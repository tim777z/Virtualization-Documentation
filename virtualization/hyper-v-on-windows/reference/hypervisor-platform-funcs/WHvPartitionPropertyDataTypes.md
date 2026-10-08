# Partition Property Data Types
**Note: These APIs are not yet publically available and will be included in a future Windows release.**

## Syntax
```C
typedef enum {Â 
    WHvPartitionPropertyCodeExtendedVmExitsÂ Â Â Â Â Â Â  = 0x00000001,Â 
    Â 
    WHvPartitionPropertyCodeProcessorVendorÂ Â Â Â Â Â Â  = 0x00001000,Â 
    WHvPartitionPropertyCodeProcessorFeaturesÂ Â Â Â Â  = 0x00001001,Â 
    WHVPartitionPropertyCodeProcessorClFlushSizeÂ Â  = 0x00001002,Â 
    Â 
    WHvPartitionPropertyCodeProcessorCountÂ Â Â Â Â Â Â Â  = 0x00001fffÂ 
} WHV_PARTITION_PROPERTY_CODE;Â 
Â 
typedef struct {Â 
    WHV_PARTITION_PROPERTY_CODE PropertyCode;Â 
    Â 
    union {Â 
        WHV_EXTENDED_VM_EXITS ExtendedVmExits; // See VID_WHV_IOCTL_GET_CAPABILITYÂ 
        WHV_PROCESSOR_VENDOR ProcessorVendor; // HV_PROCESSOR_VENDORÂ 
        WHV_PROCESSOR_FEATURES ProcessorFeatures; // HV_PARTITION_PROCESSOR_FEATURESÂ 
        UINT8 ProcessorClFlushSize;Â 
    };Â 
} WHV_GET_PARTITION_PROPERTY_OUTPUT;Â 
```


## Remarks

The `WHvPartitionExtendedVmExits` property controls the set of additional operations by a virtual processor that should cause the execution of the processor to exit and to return to the caller of the [`WHvRunVirtualProcessor`](WHvRunVirtualProcessor.md) function.

The `WHvPartitionProcessorXXX` properties control the processor features that are made available to the virtual processor of the partition. These properties can only be configured during the initial creation of the partition, prior to calling `WHvInitializePartition`.
