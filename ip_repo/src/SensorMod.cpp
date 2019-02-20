

/***************************** Include Files *******************************/
#include "SensorMod.hpp"

/************************** Function Definitions ***************************/
SensorMod::SensorMod(const u32 local_sensorMod_addr, 
            float* rawPos_data, float* rawCurr_data, float* rawVolt_data,
            float* Pos_data, float* Vel_data, float* Curr_data){
    
    my_rawPosData = rawPos_data;
    my_rawCurrData = rawCurr_data;
    my_rawVoltData = rawVolt_data;
    my_PosData = Pos_data;
    my_VelData = Vel_data;
    my_CurrData = Curr_data;

    sensorMod_addr = local_sensorMod_addr;

    SensorMod::Init();
}

bool SensorMod::Init(){
	SensorMod::SENSORMOD_mWriteReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_FLAG, SENSORMOD_AXI_RESETMASK);

    float sum = 0;
    sensorMod_data._Xuint32 = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_CURR);
    sum += sensorMod_data._Xfloat32;
    sensorMod_data._Xuint32 = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_POS);
    sum += sensorMod_data._Xfloat32;
    sensorMod_data._Xuint32 = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_VEL);
    sum += sensorMod_data._Xfloat32;

    if (sum == 0){
		return(true);
    }else{
    	return(false);
    }
}

void SensorMod::Compute(){
    sensorMod_data._Xfloat32 = *my_rawPosData;
    SensorMod::SENSORMOD_mWriteReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_RAWPOS, sensorMod_data._Xuint32);
    sensorMod_data._Xfloat32 = *my_rawCurrData;
    SensorMod::SENSORMOD_mWriteReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_RAWCURR, sensorMod_data._Xuint32);
    sensorMod_data._Xfloat32 = *my_rawVoltData;
    SensorMod::SENSORMOD_mWriteReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_RAWVOLT, sensorMod_data._Xuint32);
    
}

void SensorMod::Read(){
	sensorMod_data._Xuint32 = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_CURR);
	*my_CurrData = sensorMod_data._Xfloat32;
	sensorMod_data._Xuint32 = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_POS);
	*my_PosData = sensorMod_data._Xfloat32;
	sensorMod_data._Xuint32 = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_VEL);
	*my_VelData = sensorMod_data._Xfloat32;

}

bool SensorMod::Compute_Read(){
	SensorMod::Compute();
    bool local_flag = SensorMod::Wait();
    if (local_flag){
    	SensorMod::Read();
        return true;
    }else{
    	return false;
    }

}

bool SensorMod::IsDone(){
    u32 flag_reg = SensorMod::SENSORMOD_mReadReg(sensorMod_addr, SENSORMOD_AXI_OFFSET_FLAG);
		if (flag_reg == SENSORMOD_AXI_ISDONEMASK){
            return true;
        }else{
            return false;
        }
}

bool SensorMod::Wait(){
    bool local_flag = true;
    u32 local_cont;
    while (local_flag) {
    	local_cont++;
        if (SensorMod::IsDone()) 					local_flag = false;
        if (local_cont == SENSORMOD_AXI_TIMEOUT)	return false;
	}
    return true;
}

void SensorMod::SENSORMOD_mWriteReg(const u32 BaseAddress, const u32 RegOffset, u32 Data){
	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data));
}
u32 SensorMod::SENSORMOD_mReadReg(const u32 BaseAddress, const u32 RegOffset){
	return Xil_In32((BaseAddress) + (RegOffset));
}
