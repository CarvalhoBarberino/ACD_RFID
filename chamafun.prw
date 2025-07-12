#Include 'Protheus.CH'
#include 'parmtype.ch'
#Include 'Totvs.ch'

/*
@author Thigo Valerio
@since 20/05/2019
*/

#DEFINE senhaChumbadaNofonte '2469' // Coloque aqui a senha que vc deseja antes de compilar
#DEFINE funcaoChubadaNoFonte 'U_UACDI011' // Coloque aqui a função que vc deseja executar automáticamente antes de compilar
//#DEFINE HABILITA_FUNCAO_VAI // Usar apenas no RPO de testes. Habilita funcionamento da funcao vai()

Static Function fOK()
	If ALLTRIM(cSenha) <> senhaChumbadaNofonte
		MsgStop('Senha não Confere !!!')
		cSenha := Space(10)
		dlgRefresh(Senhadlg)
	Else
		_lReturn := .T.
		Senhadlg:End()
	Endif
Return

Static Function fDigSenha()
	Local oGet
	Private Senhadlg
	Private cSenha := Space(20)

	DEFINE DIALOG Senhadlg TITLE OemToAnsi('Liberação de Acesso')	FROM 80,80 TO 200,300	PIXEL
	@ 010,010 Say OemToAnsi('Informe a senha para o acesso ?')		SIZE 150,8 OF Senhadlg	PIXEL
	@ 020,010 GET oGet VAR cSenha									SIZE 50,12 OF Senhadlg	PIXEL PASSWORD
	@ 040,060 BUTTON 'Ok'											SIZE 30,14				PIXEL ACTION (fOK())
	@ 040,010 BUTTON 'Sair'											SIZE 30,14				PIXEL ACTION Senhadlg:End()
	ACTIVATE DIALOG Senhadlg CENTERED
Return(_lReturn)

user function Chamafun()
	Local cFunc
	Private _lReturn	:= .F.
	IF !fDigSenha()
		Return
	Endif
	cFunc:=	ALLTRIM(FWInputBox('Digite a User Function que deseja chamar', funcaoChubadaNoFonte))
	IF !Empty(cFunc)
		IF UPPER(LEFT(cFunc,2)) == 'U_'
			cFunc := substr(cFunc,3,len(cFunc)-2)
		ENDIF
		IF ExistBlock(cFunc)
			ExecBlock(cFunc)
		ELSE
			ALERT('User Function' + cFunc + ' não compilada.')
		ENDIF
	else
		MsgStop('nome de função vazio')
	endif
return

	#ifdef HABILITA_FUNCAO_VAI
User Function vai()
	If ExistBlock(funcaoChubadaNoFonte)
		ExecBlock(funcaoChubadaNoFonte)
	EndIf
return
#endif
