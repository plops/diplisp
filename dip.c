#include <diplib.h>
#include <dipio.h>
#include <stdio.h>

char *fn ="/home/martin/dip/images/cross.ics";
char *out = "/dev/shm/o.ics";
char *unit= "mm";

#define c(fun) \
  do{									\
  dip_Error e;								\
  if(DIP_OK!=(e=fun))							\
    printf("error: %s %s\n",e->function,e->message);	\
  }while(0)
  

int
main()
{
  c(dip_Initialise());
  c(dipio_Initialise());
  dip_Resources res;
  c(dip_ResourcesNew(&res,0));
  dip_Image img;
  c(dip_ImageNew(&img,res));
  dip_String fn_d,out_d,unit_d;

  c(dip_StringNew(&fn_d,0,fn,res));
  c(dip_StringNew(&out_d,0,fn,res));
  c(dip_StringNew(&unit_d,0,fn,res));
  dip_Boolean recognizedp;
  //dipio_ImageFileGetInfo(img,fn_d,0,DIP_FALSE,&recognizedp,res);
  printf("%ld\n",fn_d->size);
  c(dipio_ImageRead(img,fn_d,0,DIP_FALSE,&recognizedp));
  dip_ImageType type;
  c(dip_ImageGetType(img,&type));
  dip_DataType dtype;
  c(dip_ImageGetDataType(img,&dtype));

  // sint64
  printf("type=%ld dtype=%ld recognizedp=%d\n",type,dtype,recognizedp);
  return 0;
}
