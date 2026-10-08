# I/O Port Access for QEMU
**Note: These APIs are not yet publically available and will be included in a future Windows release..**

## Syntax
```C
// Context data for an exit caused by an I/O port accessÂ 
typedef struct {Â 
    UINT32 IsWrite : 1;Â 
    UINT32 AccessSize: 3;Â 
    UINT32 StringOp : 1;Â 
    UINT32 RepPrefix : 1;Â 
    UINT32 Reserved : 26;Â 
} WHV_X64_IO_PORT_ACCESS_INFO;Â 
Â 
typedef struct {Â 
    WHV_VP_INSTRUCTION_CONTEXT Instruction;Â 
    WHV_VP_EXECUTION_STATE VpState;Â 
    WHV_X64_IO_PORT_ACCESS_INFO AccessInfo;Â 
    UINT16 PortNumber;Â 
    UINT64 Rax;Â 
    UINT64 Rcx;Â 
    UINT64 Rsi;Â 
    UINT64 Rdi;Â 
    WHV_X64_SEGMENT_REGISTER Ds;Â 
    WHV_X64_SEGMENT_REGISTER Es;Â 
} WHV_X64_IO_PORT_ACCESS_CONTEXT;Â 
```

## Remarks

Information about exits caused by the virtual processor executing an I/O port instruction (IN, OUT, INS, and OUTS) is provided in the `WHV_X64_IO_PORT_ACCESS_CONTEXT` structure. The context information includes the I/O port address, which allows the virtualization stack to forward the exit to the device emulation logic of the device that uses the I/O port accessed by the virtual processor.Â 
