
#ifndef SENSORMOD_H
#define SENSORMOD_H


/****************** Include Files ********************/
#include "xil_io.h"

#define OFFSET_POS      0x02
#define OFFSET_CURR     0x04
#define OFFSET_VOLT     0x06

#define OFFSET_POS_F    0x02
#define OFFSET_VEL_F    0x04
#define OFFSET_CURR_F   0x06

#define OFFSET_DT       0x00
#define OFFSET_R        0x08
#define OFFSET_CEN_CURR 0x16
#define OFFSET_Q0       0x18
#define OFFSET_Q12      0x20
#define OFFSET_Q3       0x28
#define OFFSET_b01      0x30
#define OFFSET_a1       0x38

#define OFFSET_SEN_F    0x00
#define OFFSET_SEN      0x40
#define OFFSET_CONF     0x80

void sensorMod_conf_R()

#endif // SENSORMOD_H
