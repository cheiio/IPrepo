

/***************************** Include Files *******************************/
#include "ImpedanceController.h"

/************************** Function Definitions ***************************/

XStatus IMPEDANCECONTROLLER_SetParameters(float M, float K, float B, float P,
                                        float dt, float outMax, float outMin,
                                        const u32 local_addr){
    union impCont_type impCont_data;

    impCont_data._Xfloat32 = 1/M;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_M, impCont_data._Xuint32);
    impCont_data._Xfloat32 = K;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_K, impCont_data._Xuint32);
    impCont_data._Xfloat32 = B;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_B, impCont_data._Xuint32);
    impCont_data._Xfloat32 = dt;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_dt, impCont_data._Xuint32);
    impCont_data._Xfloat32 = dt/2;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_dt_half, impCont_data._Xuint32);
    impCont_data._Xfloat32 = outMax;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_outMax, impCont_data._Xuint32);
    impCont_data._Xfloat32 = outMin;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_outMin, impCont_data._Xuint32);

    return XST_SUCCESS; 
}

XStatus IMPEDANCECONTROLLER_SetPoint(float setPoint, const u32 local_addr){
    union impCont_type impCont_data;

    impCont_data._Xfloat32 = setPoint;
    IMPEDANCECONTROLLER_mWriteReg(local_addr, IMPCONT_REG_OFFSET_setPoint, impCont_data._Xuint32);
    return XST_SUCCESS; 
}

float IMPEDANCECONTROLLER_getOutput(const u32 local_addr){
    union impCont_type impCont_data;
    impCont_data._Xuint32 = IMPEDANCECONTROLLER_mReadReg(local_addr, IMPCONT_REG_OFFSET_outPut);
    return impCont_data._Xfloat32;
}

float IMPEDANCECONTROLLER_getM(const u32 local_addr){
    union impCont_type impCont_data;
    impCont_data._Xuint32 = IMPEDANCECONTROLLER_mReadReg(local_addr, IMPCONT_REG_OFFSET_M);
    return (1/impCont_data._Xfloat32);
}
float IMPEDANCECONTROLLER_getB(const u32 local_addr){
    union impCont_type impCont_data;
    impCont_data._Xuint32 = IMPEDANCECONTROLLER_mReadReg(local_addr, IMPCONT_REG_OFFSET_B);
    return impCont_data._Xfloat32;
}
float IMPEDANCECONTROLLER_getP(const u32 local_addr){
    union impCont_type impCont_data;
    impCont_data._Xuint32 = IMPEDANCECONTROLLER_mReadReg(local_addr, IMPCONT_REG_OFFSET_K);
    return impCont_data._Xfloat32;
}
float IMPEDANCECONTROLLER_getdt(const u32 local_addr){
    union impCont_type impCont_data;
    impCont_data._Xuint32 = IMPEDANCECONTROLLER_mReadReg(local_addr, IMPCONT_REG_OFFSET_dt);
    return impCont_data._Xfloat32;
}