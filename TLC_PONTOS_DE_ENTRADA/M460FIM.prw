#include "totvs.ch"


/*/{Protheus.doc} M460FIM
Grava��o da NF saida - Este P.E. � chamado ap�s a grava��o da NF de Sa�da e fora da transa��o.
@type  user function
@author Emerson Nascimento TwoIT
@since 24/08/2025
@version 1.000
@param nil
@return nil
@example
(examples)
@see (links_or_references)
/*/
USER FUNCTION M460FIM() //U_M460FIM()
Local cNumNFS   := PARAMIXB[1] as character // N�mero da NF
Local cSerieNFS := PARAMIXB[2] as character // S�rie da NF
//Local cClieFor  := PARAMIXB[3] as character // Cliente/fornecedor da NF
//Local cLoja     := PARAMIXB[4] as character // Loja da NF
//Local cCodRet as character
//Local cRetorno as character
Local oFaturmento := Telecontrol.Integracao.Faturamento.TTLCFaturamento():New()

    oFaturmento:Cadastra(cNumNFS, cSerieNFS/*, @cCodRet, @cRetorno*/)
    FWFreeObj(@oFaturmento)

RETURN
