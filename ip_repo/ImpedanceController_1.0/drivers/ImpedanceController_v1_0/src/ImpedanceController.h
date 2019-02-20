
#ifndef IMPEDANCECONTROLLER_H
#define IMPEDANCECONTROLLER_H


/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"

#define IMPCONT_REG_OFFSET_M               0
#define IMPCONT_REG_OFFSET_K               4
#define IMPCONT_REG_OFFSET_B               8
#define IMPCONT_REG_OFFSET_P               12
#define IMPCONT_REG_OFFSET_dt              16
#define IMPCONT_REG_OFFSET_dt_half         20
#define IMPCONT_REG_OFFSET_outMax          24
#define IMPCONT_REG_OFFSET_outMin          28
#define IMPCONT_REG_OFFSET_setPoint        32
#define IMPCONT_REG_OFFSET_outPut          36
#define IMPEDANCECONTROLLER_S00_AXI_SLV_REG10_OFFSET    40
#define IMPEDANCECONTROLLER_S00_AXI_SLV_REG11_OFFSET    44
#define IMPEDANCECONTROLLER_S00_AXI_SLV_REG12_OFFSET    48
#define IMPEDANCECONTROLLER_S00_AXI_SLV_REG13_OFFSET    52
#define IMPEDANCECONTROLLER_S00_AXI_SLV_REG14_OFFSET    56
#define IMPEDANCECONTROLLER_S00_AXI_SLV_REG15_OFFSET    60


/**************************** Type Definitions *****************************/
union impCont_type {
	        u32 	_Xuint32;
	        float 	_Xfloat32;
        };
/**
 *
 * Write a value to a IMPEDANCECONTROLLER register. A 32 bit write is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is written.
 *
 * @param   BaseAddress is the base address of the IMPEDANCECONTROLLERdevice.
 * @param   RegOffset is the register offset from the base to write to.
 * @param   Data is the data written to the register.
 *
 * @return  None.
 *
 * @note
 * C-style signature:
 * 	void IMPEDANCECONTROLLER_mWriteReg(u32 BaseAddress, unsigned RegOffset, u32 Data)
 *
 */


#define IMPEDANCECONTROLLER_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

/**
 *
 * Read a value from a IMPEDANCECONTROLLER register. A 32 bit read is performed.
 * If the component is implemented in a smaller width, only the least
 * significant data is read from the register. The most significant data
 * will be read as 0.
 *
 * @param   BaseAddress is the base address of the IMPEDANCECONTROLLER device.
 * @param   RegOffset is the register offset from the base to write to.
 *
 * @return  Data is the data from the register.
 *
 * @note
 * C-style signature:
 * 	u32 IMPEDANCECONTROLLER_mReadReg(u32 BaseAddress, unsigned RegOffset)
 *
 */
#define IMPEDANCECONTROLLER_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

/************************** Function Prototypes ****************************/
/**
 *
 * Run a self-test on the driver/device. Note this may be a destructive test if
 * resets of the device are performed.
 *
 * If the hardware system is not built correctly, this function may never
 * return to the caller.
 *
 * @param   baseaddr_p is the base address of the IMPEDANCECONTROLLER instance to be worked on.
 *
 * @return
 *
 *    - XST_SUCCESS   if all self-test code passed
 *    - XST_FAILURE   if any self-test code failed
 *
 * @note    Caching must be turned off for this function to work.
 * @note    Self test may fail if data memory and device are not on the same bus.
 *
 */
XStatus IMPEDANCECONTROLLER_Reg_SelfTest(void * baseaddr_p);
XStatus IMPEDANCECONTROLLER_SetParameters(float M, float K, float B, float P,
                                        float dt, float outMax, float outMin,
                                        const u32 local_addr);
XStatus IMPEDANCECONTROLLER_SetPoint(float setPoint, const u32 local_addr);
float IMPEDANCECONTROLLER_getOutput(const u32 local_addr);
float IMPEDANCECONTROLLER_getM(const u32 local_addr);
float IMPEDANCECONTROLLER_getB(const u32 local_addr);
float IMPEDANCECONTROLLER_getP(const u32 local_addr);
float IMPEDANCECONTROLLER_getdt(const u32 local_addr);

#endif // IMPEDANCECONTROLLER_H
