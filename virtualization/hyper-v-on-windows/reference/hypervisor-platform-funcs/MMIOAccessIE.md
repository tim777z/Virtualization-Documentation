# MMIO Access for QEMU
**Note: These APIs are not yet publically available and will be included in a future Windows release.**

## Syntax
```C
typedef struct {Â 
    UINT64 GpaAddress; // GPA address of the memory accessÂ 
    UINT8 Direction; // Read or writeÂ 
    UINT8 AccessSize; // 1, 2, 4, or 8 bytesÂ 
    union {Â 
        UINT64 Value; // Input value (for write), output value (for read)Â 
        UINT64 GpaAddress2; // GPA address of the second instruction operandÂ 
    };Â 
} MMIO_ACCESS_INFO;Â 
``` 

## Remarks
This information is derived by decoding the instruction that caused an `RunVpExitMemoryAccess` exit for a virtual processor.Â 
