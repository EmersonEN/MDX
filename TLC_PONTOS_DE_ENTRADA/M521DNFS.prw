#include "totvs.ch"


/*/{Protheus.doc} M521DNFS
Exclus�o da NF saida - Este ponto de entrada est� contido na fun��o MaDelNfs e ser� executado ap�s a conclus�o dos lan�amentos cont�beis.
Este ponto possui como par�metro o Array aPedido, que somente ter� conte�do caso o pergunte "Retornar Ped.Venda" esteja igual a "Apto a Faturar".
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
USER FUNCTION M521DNFS()

Local oFaturmento := Telecontrol.Integracao.Faturamento.TTLCFaturamento():New()

    oFaturmento:Cancela()
    FWFreeObj(@oFaturmento)

RETURN
