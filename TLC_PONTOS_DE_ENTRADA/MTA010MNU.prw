#include "totvs.ch"
#include "TLC_DEFINE.CH" 
#include "parmtype.ch" 

Static cMVRProd := GetMV("TI_TLCPROD",.F.,"SB1->B1_TIPO == 'PA'")
Static cMVRPeca := GetMV("TI_TLCPECA",.F.,"SB1->B1_TIPO == 'PI'")


USER FUNCTION MTA010MNU()
Local cConTlc as character
Local cCadTlc as character

    cConTlc := "Telecontrol.Funcoes.U_TLCConsulta(if("+cMVRProd+","+cValTochar(TCCON_PRODUTO)+",if("+cMVRPeca+","+cValTochar(TCCON_PECA)+",-1)))"
    cCadTlc := "Telecontrol.Funcoes.U_TLCCadastra(if("+cMVRProd+","+cValTochar(TCCON_PRODUTO)+",if("+cMVRPeca+","+cValTochar(TCCON_PECA)+",-1)))"

    aAdd(aRotina, {"Cons. Telecontrol",cConTlc, 0, 8, 1, nil} )
    aAdd(aRotina, {"Cad. Telecontrol",cCadTlc, 0, 8, 1, nil} )
RETURN
