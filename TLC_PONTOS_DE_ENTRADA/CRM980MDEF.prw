#include "totvs.ch"

USER FUNCTION CRM980MDEF()
RETURN {    {'Consulta Telecontrol',;   								// Titulo para o bot�o
                'sdufind',; 											// Nome do Bitmap para exibi��o
                {|| Telecontrol.Funcoes.U_TLCConsulta(1)},; 			// CodeBlock a ser executado
                'Consulta o cadastro deste cliente no Telecontrol.'},;	// ToolTip (Opcional)
            {'Cadastra no Telecontrol',;    							// Titulo para o bot�o
                'sduimport',;											// Nome do Bitmap para exibi��o
                {|| Telecontrol.Funcoes.U_TLCCadastra(1)},;     		// CodeBlock a ser executado
                'Consulta o cadastro deste cliente no Telecontrol.'};	// ToolTip (Opcional)
        }

