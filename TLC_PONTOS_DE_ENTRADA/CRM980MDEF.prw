#include "totvs.ch"

USER FUNCTION CRM980MDEF()
Local aRot := {}
/*
    aAdd(aRot, {'Consulta Telecontrol',;   								// Titulo para o botão
                'sdufind',; 											// Nome do Bitmap para exibição
                {|| Telecontrol.Funcoes.U_TLCConsulta(1)},; 			// CodeBlock a ser executado
                'Consulta o cadastro deste cliente no Telecontrol.'})	// ToolTip (Opcional)

    aAdd(aRot, {'Cadastra no Telecontrol',;    							// Titulo para o botão
                'sduimport',;											// Nome do Bitmap para exibição
                {|| Telecontrol.Funcoes.U_TLCCadastra(1)},;     		// CodeBlock a ser executado
                'Consulta o cadastro deste cliente no Telecontrol.'})	// ToolTip (Opcional)
*/
    aAdd(aRot, {'Consulta Telecontrol',;   								// Titulo para o botão
                'Telecontrol.Funcoes.U_TLCConsulta(1)',; 			    // CodeBlock a ser executado
                2,;                                                     // Operação MVC
                0})                                                     // Acesso

    aAdd(aRot, {'Cadastra no Telecontrol',;    							// Titulo para o botão
                'Telecontrol.Funcoes.U_TLCCadastra(1)',;     		    // CodeBlock a ser executado
                2,;                                                     // Operação MVC
                0})                                                     // Acesso

RETURN aRot
