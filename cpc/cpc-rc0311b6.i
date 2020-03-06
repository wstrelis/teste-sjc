       /******************************************************************************
    Programa .....: cpc-rc0311b6.i
    Data .........: 15 de Abril de 2008
    Sistema ......: RC - Revisao de Contas Medicas
    Empresa ......: DATASUL Saude  
    Cliente ......: UNIMED Nordeste RS
    Programador ..: Rudah Billig
    Objetivo .....: Definicao das temps de entrada e saida da cpc-rc0311b6.p
*******************************************************************************/

def temp-table tmp-cpc-rc0311b6-entrada  no-undo
         field in-evento-programa        as char format "x(10)"
         field nm-ponto-chamada-cpc      as char format "x(15)"
         field cd-unidade-executante     like moviproc.cd-unidade-prestador
         field cd-prestador-executante   like moviproc.cd-prestador
         field cd-procedimento           as int format 99999999
         field cd-esp-prest-executante   like moviproc.cd-esp-prest-executante
         field dt-realizacao             like moviproc.dt-realizacao
         field nr-rowid-moviproc         as rowid
         field nr-rowid-docrecon         as rowid
         field nr-rowid-usuario          as rowid
         field nr-rowid-out-uni          as rowid
         field qt-digitos-proced         as handle
         field lg-anestesista            as log
         field cd-proc-insu              like presmovt.cd-proc-insu
         field cd-unidade-carteira       like car-ide.cd-unimed
         field lg-urgencia               as log
         field qt-procedimento           as int
         field cd-tab-preco-proc         like propost.cd-tab-preco-proc
         field lg-rtvalglo-cpc           as log
         field cd-unidade-guia           like guiautor.cd-unidade
         field aa-guia-atendimento       like guiautor.aa-guia-atendimento
         field nr-guia-atendimento       like guiautor.nr-guia-atendimento
         field nr-rowid-tranrevi         as rowid
         field cd-tipo-cob-cpc           like moviproc.cd-tipo-cob
         field vl-uso-indevido-cpc       like moviproc.vl-perc-usu-indevido
         field cd-validacao-cpc          like moviproc.cd-validacao
         field cd-user-validacao-cpc     like moviproc.cd-user-validacao
         field cd-forma-pagto-cob-cpc    like formpaga.cd-forma-pagto
         field cd-tipo-pagamento-cpc     like moviproc.cd-tipo-pagamento
         field dt-realizacao-cpc         like moviproc.dt-realizacao
         field cd-tipo-insumo-cpc        like mov-insu.cd-tipo-insumo
         field cd-insumo-cpc             like mov-insu.cd-insumo
         field cd-unidade-cpc            like moviproc.cd-unidade
         field cd-unidade-prestadora-cpc like moviproc.cd-unidade-prestadora
         field cd-transacao-cpc          like moviproc.cd-transacao
         field nr-serie-doc-original-cpc like moviproc.nr-serie-doc-original
         field nr-doc-original-cpc       like moviproc.nr-doc-original
         field nr-doc-sistema-cpc        like moviproc.nr-doc-sistema
         field nr-processo-cpc           like moviproc.nr-processo
         field nr-seq-digitacao-cpc      like moviproc.nr-seq-digitacao
         field lg-trab-cooperado           as log
         field vl-cobrado                like mov-insu.vl-cobrado
         field pc-taxa-aca               like unicamco.pc-taxa-aca
         field pc-taxa-acp               like unicamco.pc-taxa-acp
         field vl-principal              like moviproc.vl-principal
         field vl-auxiliar               like moviproc.vl-auxiliar
         field vl-taxa-out-uni-prin      like moviproc.vl-taxa-out-uni-prin
         field vl-taxa-out-uni-auxi      like moviproc.vl-taxa-out-uni-auxi
		 field dt-digitacao             like moviproc.dt-realizacao
		 field cd-unidade-prest-principal  like unimed.cd-unimed        
         field cd-prestador-principal      like moviproc.cd-prestador    
         field lg-inclui-pacote            as log
         field cd-classe-erro            like moviproc.cd-classe-erro
         field cd-unidade                like docrecon.cd-unidade             
         field cd-unidade-prestadora     like docrecon.cd-unidade-prestadora  
         field cd-transacao              like docrecon.cd-transacao           
         field nr-serie-doc-original     like docrecon.nr-serie-doc-original  
         field nr-doc-original           like docrecon.nr-doc-original        
         field nr-doc-sistema            like docrecon.nr-doc-sistema
         field rw-docrecon               as rowid
         field vl-taxa-out-uni-cobrado   like moviproc.vl-taxa-out-uni-cob.

def temp-table tmp-cpc-rc0311b6-saida      no-undo
         field lg-erro                     as log
         field cd-classe-erro              like movrcglo.cd-classe-erro
         field ds-mensagem                 as char format "x(75)"
         field cd-unidade-encaminhamento   like moviproc.cd-unidade-prestador
         field cd-prestador-encaminhamento like moviproc.cd-prestador
         field lg-urgencia                 as log
         field lg-adicional-urgencia       as log
         field lg-solicita-adicional       as log
         field lg-espec-anest              as log
         field lg-busca-pacote-aux         as log
         field lg-anestesiologista         as log
         field lg-rtvalglo-cpc             as log
         field cd-tipo-cob-cpc             like moviproc.cd-tipo-cob
         field vl-uso-indevido-cpc         like moviproc.vl-perc-usu-indevido
         field cd-validacao-cpc            like moviproc.cd-validacao
         field cd-user-validacao-cpc       like moviproc.cd-user-validacao
         field cd-forma-pagto-cob-cpc      like formpaga.cd-forma-pagto
         field cd-tipo-pagamento-cpc       like moviproc.cd-tipo-pagamento
         field lg-mostra-mensagem          as log
         field lg-continua		           as log 
         field vl-principal                like moviproc.vl-principal
         field vl-auxiliar                 like moviproc.vl-auxiliar
         field vl-taxa-out-uni-prin        like moviproc.vl-taxa-out-uni-prin
         field vl-taxa-out-uni-auxi        like moviproc.vl-taxa-out-uni-auxi
         field lg-undo-retry               as log                  
         field nr-cpc-ant-inc-pacote-restr as int
         field lg-cpc-ant-inc-pacote-restr as log.                  

