
function ini= ini_DEM

global INT U V W



 % Variables setting
 INT=10000; % total nodes 
 
 U(3,INT)=0.0; % nodal displacement, U=x,V=y,W=z, i-1,i,i+1  time_ step
 V(3,INT)=0.0;
 W(3,INT)=0.0;
 ini=1;
 end
