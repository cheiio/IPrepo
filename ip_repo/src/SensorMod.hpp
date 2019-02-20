
#ifndef SENSORMOD_HPP
#define SENSORMOD_HPP


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xil_io.h"

#define SENSORMOD_AXI_OFFSET_FLAG       0
#define SENSORMOD_AXI_OFFSET_RAWPOS     4
#define SENSORMOD_AXI_OFFSET_RAWCURR    8
#define SENSORMOD_AXI_OFFSET_RAWVOLT    12
#define SENSORMOD_AXI_OFFSET_POS        16
#define SENSORMOD_AXI_OFFSET_VEL        20
#define SENSORMOD_AXI_OFFSET_CURR       24
#define SENSORMOD_AXI_OFFSET            28
#define SENSORMOD_AXI_RESETMASK         0x0F
#define SENSORMOD_AXI_ISDONEMASK        0xF0
#define SENSORMOD_AXI_TIMEOUT        	10000

/**************************** Type Definitions *****************************/
union sensorMod_type {
	        u32 	_Xuint32;
	        float 	_Xfloat32;
        };

/************************** Driver Class Definition ************************/
/**
 *
 */
class SensorMod{
    public:
    // commonly used functions *********************************************/
        SensorMod(const u32 local_sensorMod_addr, 
                float* rawPos_data, float* rawCurr_data, float* rawVolt_data,
                float* Pos_data, float* Vel_data, float* Curr_data);
        bool Init();
        void Compute();
        void Read();
        bool Compute_Read();
        bool IsDone();
        bool Wait();
    
    //available but not commonly used functions ****************************/
        
    private:
        void SENSORMOD_mWriteReg(const u32 BaseAddress, const u32 RegOffset, u32 Data);
        u32 SENSORMOD_mReadReg(const u32 BaseAddress, const u32 RegOffset);

        union sensorMod_type sensorMod_data;
        u32 sensorMod_addr;
        u32 AXI_OUT_DATA;
        float AXI_IN_DATA;

        float *my_rawPosData, *my_rawCurrData, *my_rawVoltData; 	// Data in
        float *my_PosData, *my_CurrData, *my_VelData;			// Data out
};

#endif // SENSORMOD_H
