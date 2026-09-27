#include <windows.h>

DWORD __stdcall RtlAddGrowableFunctionTable(
    PVOID* DynamicTableHandle,
    PRUNTIME_FUNCTION FunctionTable,
    DWORD EntryCount,
    DWORD MaximumEntryCount,
    ULONG_PTR RangeBase,
    ULONG_PTR RangeEnd)
{
    if (DynamicTableHandle) {
        *DynamicTableHandle = (PVOID)FunctionTable;
    }
    BOOLEAN ok = RtlAddFunctionTable(FunctionTable, EntryCount, RangeBase);
    return ok ? 0 : 0xC0000001;
}

VOID __stdcall RtlDeleteGrowableFunctionTable(PVOID DynamicTableHandle)
{
    if (DynamicTableHandle) {
        RtlDeleteFunctionTable((PRUNTIME_FUNCTION)DynamicTableHandle);
    }
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    return TRUE;
}
