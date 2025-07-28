#include "totvs.ch"
#include "TLC_DEFINE.CH"
#include "parmtype.ch"


USER FUNCTION MA020ROT()
Local aRotAdic := {} as array

    aAdd(aRotAdic, {"Cons. Posto Telecontrol","Telecontrol.Funcoes.U_TLCConsulta("+cValTochar(TCCON_POSTO)+")", 0, 8, 1, nil} )
    aAdd(aRotAdic, {"Cad. Posto Telecontrol","Telecontrol.Funcoes.U_TLCCadastra("+cValTochar(TCCON_POSTO)+")", 0, 8, 1, nil} )

RETURN aRotAdic
