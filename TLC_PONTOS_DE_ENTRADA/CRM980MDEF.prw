#include "totvs.ch"

USER FUNCTION CRM980MDEF()
Local aRot := {}
/*
    aAdd(aRot, {'Consulta Telecontrol',;   								// Titulo para o bot�o
                'sdufind',; 											// Nome do Bitmap para exibi��o
                {|| Telecontrol.Funcoes.U_TLCConsulta(1)},; 			// CodeBlock a ser executado
                'Consulta o cadastro deste cliente no Telecontrol.'})	// ToolTip (Opcional)

    aAdd(aRot, {'Cadastra no Telecontrol',;    							// Titulo para o bot�o
                'sduimport',;											// Nome do Bitmap para exibi��o
                {|| Telecontrol.Funcoes.U_TLCCadastra(1)},;     		// CodeBlock a ser executado
                'Consulta o cadastro deste cliente no Telecontrol.'})	// ToolTip (Opcional)
*/
    aAdd(aRot, {'Consulta Telecontrol',;   								// Titulo para o bot�o
                'Telecontrol.Funcoes.U_TLCConsulta(1)',; 			    // CodeBlock a ser executado
                2,;                                                     // Opera��o MVC
                0})                                                     // Acesso

    aAdd(aRot, {'Cadastra no Telecontrol',;    							// Titulo para o bot�o
                'Telecontrol.Funcoes.U_TLCCadastra(1)',;     		    // CodeBlock a ser executado
                2,;                                                     // Opera��o MVC
                0})                                                     // Acesso

RETURN aRot
