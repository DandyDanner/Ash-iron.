"""Surface-distance skinning avoids assigning a nearby trouser to a moving hand."""
import heapq
import numpy as np

def bind(P,edges,points,bones,arm_masks,cape,gear,labels,names):
 n=len(P);adj=[[] for _ in range(n)]
 for a,b in edges:
  length=float(np.linalg.norm(P[a]-P[b]));adj[a].append((b,length));adj[b].append((a,length))
 ends={}
 for side in ['Left','Right']:
  ends[side+'Leg']=points[side+'Knee'];ends[side+'Knee']=points[side+'Knee']+np.array([0,0,-.48]);ends[side+'Arm']=points[side+'Elbow'];ends[side+'Elbow']=points[side+'Hand'];ends[side+'Hand']=points[side+'Hand']+(points[side+'Hand']-points[side+'Elbow'])*.35
 ends.update(Body=points['Body']+np.array([0,0,.13]),Torso=points['Torso']+np.array([0,0,.36]),Head=points['Head']+np.array([0,0,.26]),Cape=points['Cape']+np.array([0,.08,-.30]))
 distances=np.full((n,len(bones)),100.,np.float32)
 for bi,name in enumerate(bones):
  if name=='Cape':continue
  a,b=points[name],ends[name];allowed=np.ones(n,bool)
  if name.startswith(('Left','Right')) and any(t in name for t in ['Arm','Elbow','Hand']):
   allowed=arm_masks[0 if name.startswith('Left') else 1]&~gear
  elif name.endswith(('Leg','Knee')):allowed=P[:,2]<1.18
  elif name=='Head':allowed=P[:,2]>1.72
  else:allowed=(abs(P[:,0])<.20)&(P[:,2]>1.05)&(P[:,2]<1.68)&~gear
  ids=np.nonzero(allowed)[0];queue=[];d=distances[:,bi]
  for t in np.linspace(.08,.93,7):
   target=a+(b-a)*t;dist=np.linalg.norm(P[ids]-target,axis=1);v=int(ids[np.argmin(dist)]);value=float(dist.min());d[v]=min(d[v],value);heapq.heappush(queue,(float(d[v]),v))
  while queue:
   value,v=heapq.heappop(queue)
   if value>d[v]+1e-6:continue
   for w,length in adj[v]:
    nv=value+length
    if nv<float(d[w])-1e-6:d[w]=nv;heapq.heappush(queue,(float(d[w]),w))
  print('SURFACE BIND',name,flush=True)
 # Lower garments never belong to an arm even when Rodin fused them to a hand.
 protect=np.isin(labels,[names.index(n) for n in ['pants','cloth','shirt']])&(P[:,2]<1.14)
 arm_columns=[j for j,n in enumerate(bones) if any(t in n for t in ['Arm','Elbow','Hand'])]
 def constrain(w):
  w[np.ix_(protect,arm_columns)]=0
  empty=w.sum(1)<1e-8;w[empty,bones.index('Body')]=1
  w/=w.sum(1)[:,None]
 nearest=distances.min(1)
 weights=np.exp(-((distances-nearest[:,None])/.075)**2)
 weights[distances>99]=0
 weights[gear]=0;weights[gear,bones.index('Torso')]=1
 if cape.any():
  t=np.clip((P[:,2]-1.30)/.40,0,1);w=(1-t*t*(3-2*t))*.65
  weights[cape]=0;weights[cape,bones.index('Torso')]=1-w[cape];weights[cape,bones.index('Cape')]=w[cape]
 empty=weights.sum(1)<1e-8;weights[empty,bones.index('Body')]=1
 weights/=weights.sum(1)[:,None]
 constrain(weights)
 # Smooth transitions on the connected surface, preserving the collar/hem attachments.
 a=np.array([e[0] for e in edges]);b=np.array([e[1] for e in edges]);count=np.bincount(np.r_[a,b],minlength=n)
 for _ in range(10):
  new=weights.copy()
  for j in range(len(bones)):
   avg=np.bincount(np.r_[a,b],weights=np.r_[weights[b,j],weights[a,j]],minlength=n)/np.maximum(count,1)
   new[:,j]=weights[:,j]*.5+avg*.5
  weights=new;constrain(weights)
 order=np.argsort(weights,axis=1)[:,:-4];np.put_along_axis(weights,order,0,axis=1);weights/=weights.sum(1)[:,None]
 return weights
