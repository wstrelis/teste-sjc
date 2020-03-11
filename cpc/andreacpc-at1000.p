mesnsagem teste andreaaaaaaaaa eeeeeeeeee


ddsdsdada

/* CPC CRIADA PARA TRATAR PROJETO IED PONTA A PONTA - ANDREA CAETANO  - NAO APAGAR, NEM RETIRAR DA HOMOLOGACAO, POIS OS SETORES ESTAO EFETUANDO TESTES         */


/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
****************************************************************************************************************************************************************
****************************************************************************************************************************************************************/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
{include/i-license-manager.i cpc-at1000 MCP}
&ENDIF
def var c-versao as char no-undo.
assign c-versao = "7.00.000".

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

{cpc/cpc-at1000.i}
{hdp/hdsistem.i}
{rtp/rtvalida.i}.
{hdp/hdttable.i "NEW"}.


define input  parameter table for tmp-cpc-at1000-entrada.
define input  parameter table for tmp-cpc-at1000-movtos.
define output parameter table for tmp-cpc-at1000-saida. 


/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

def temp-table tmp-movtos-propria no-undo
    field cd-procedimento              like ambcbhpm.cd-amb
    field cd-tipo-insumo               like insumos.cd-tipo-insumo
    field cd-insumo                    like insumos.cd-insumo
    field cd-unidade                   like insuguia.cd-unidade-prestador
    field cd-prestador                 like insuguia.cd-prestador
    field lg-glosa                     as log
    field cd-modulo                    like mod-cob.cd-modulo
    field nr-processo                  like procguia.nr-processo
    field nr-seq-digitacao             like procguia.nr-seq-digitacao
    field qt-movto                     like insuguia.qt-insumo.

empty temp-table tmp-movtos-propria.

def var cd-modalidade-aux   like propost.cd-modalidade no-undo.
def var nr-proposta-aux     like propost.nr-proposta   no-undo.
def var nr-ter-adesao-aux   like propost.nr-ter-adesao no-undo.
def var cd-plano-aux        like propost.cd-plano      no-undo.
def var cd-tipo-plano-aux   like propost.cd-tipo-plano no-undo.
def var cd-usuario-aux      like car-ide.cd-usuario    no-undo.

assign cd-modalidade-aux    = 0
       nr-proposta-aux      = 0
       cd-plano-aux         = 0
       cd-tipo-plano-aux    = 0
       nr-ter-adesao-aux    = 0
       cd-usuario-aux       = 0.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

def var lg-sadt as log init no no-undo.
def var lg-deixar-guia-auditoria  as logical no-undo.

def buffer bf-procguia for procguia.
def buffer bf-guiautor for guiautor.





/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

function fnAutAutom returns log(input cdTipoGuia as int, input cdProc as int) forward.

/* MAIN ********************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

find first tmp-cpc-at1000-entrada no-lock no-error.
if not avail tmp-cpc-at1000-entrada 
then do:
       create tmp-cpc-at1000-saida.
       assign tmp-cpc-at1000-saida.lg-undo-retry         = yes
              tmp-cpc-at1000-saida.ds-mensagem           = "Tabela de entrada da CPC-AT1000 n’o foi informada"
              tmp-cpc-at1000-saida.cd-local-autorizacao  = tmp-cpc-at1000-entrada.cd-local-autorizacao.               .
     end.
else
do:
    find first guiautor where rowid(guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor no-lock no-error.
    
    case tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc:
        when "CONSISTE-MOVTOS" then
        do:
            run prRegrasAt1000.
            run prVerificaSeComunica.
            run prLimpaGuiaAnteriorPedidoComplemento.
        end.
        when "APOS-AUTOR-AUTO" then do:
            run prComunica.
            run prComunicaPedidoDeComplemento.
        end.
    end case.
end.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prLimpaGuiaAnteriorPedidoComplemento:
    define buffer b-guiautor        for guiautor.
    define buffer b-guiautor-ant    for guiautor.
    define variable lgComunica      as logical initial true no-undo.

    /* VALIDACAO DO ES-22-J */
    find last b-guiautor 
         where rowid(b-guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
         exclusive-lock no-error.
    
    if available b-guiautor then 
    do:
        
        if (b-guiautor.cd-unidade-carteira <> 555) then 
        do:

            if (b-guiautor.aa-guia-atendimento-ant > 0 and b-guiautor.nr-guia-atendimento-ant > 0) then 
            do: 

                /* PROCEDIMENTO */
                for each procguia of b-guiautor
                no-lock,
                    last ambproce of procguia
                no-lock:
                    if (ambproce.u-log-3 = yes) then    /* CONFIGURADO NO es-22-j PARA RESTRINGIR A COMUNICACAO COM A UNIMED ORIGEM */
                    do: 
                      assign lgComunica = false. 
                      
                      leave. 
                    end.
                end.
        
                /* INSUMOS */
                for each insuguia of b-guiautor 
                no-lock,
                    last tipoinsu of insuguia
                no-lock,
                    last insumos of insuguia
                no-lock:
                    if (insumos.u-log-1 = yes or tipoinsu.u-log-1 = yes) then  /* CONFIGURADO NO es-22-j PARA RESTRINGIR A COMUNICACAO COM A UNIMED ORIGEM */
                    do: 
                       assign lgComunica = false. 
                        leave.
                    end.
                end.
    
                /* VALIDACAO DO STATUS DA GUIA ANTERIOR */
                find last b-guiautor-ant
                    where b-guiautor-ant.cd-unidade          = b-guiautor.cd-unidade
                      and b-guiautor-ant.aa-guia-atendimento = b-guiautor.aa-guia-atendimento-ant
                      and b-guiautor-ant.nr-guia-atendimento = b-guiautor.nr-guia-atendimento-ant
                      no-lock no-error.

                if available b-guiautor-ant then 
                do:
                    if (b-guiautor-ant.in-liberado-guias <> "2") then 
                    do: 
                        assign lgComunica = false. 
                       
                    end.
                end.

                /* nao deve comunicar guias sadt de beneficiario internado */ /* verificar */
                if (b-guiautor.cd-tipo-guia >= 40 and b-guiautor.cd-tipo-guia <= 44 or b-guiautor.cd-tipo-guia >= 54 and b-guiautor.cd-tipo-guia <= 58) then 
                do: 
                   assign lgComunica = false.
                end.
        
                /*  caso os campos referentes a guia anterior estejam preenchidos a solicitacao sera tratada diretamente como PEDIDO DE COMPLEMENTO 
                    transacao(605) nao possibilitando o impedimento da comunicacao no ponto "COMUM-ORIGEM". Assim para que a solicitacao passe por 
                    tal validacao eh necessario limpar esses campos, para que a solicitacao seja tratada como PEDIDO DE AUTORIZACAO transacao(600)  
                    passando assim pelas validacoes de comunicacao.
                    
                    as informacoes da guia anterior serao salvas no campo "guiautor.u-dec-2" e preenchidas novamente no ponto "COMUM-ORIGEM".
                */

                if (not lgComunica) then 
                do:
                    assign  b-guiautor.u-dec-2 = decimal(string(b-guiautor.aa-guia-atendimento-ant) + STRING(b-guiautor.nr-guia-atendimento-ant))
                            b-guiautor.aa-guia-atendimento-ant = 0.
                            b-guiautor.nr-guia-atendimento-ant = 0.

                end.
            end.
        end.

    end.
end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prComunicaPedidoDeComplemento:

    define buffer b-guiautor        for guiautor.
    define variable lgComunica      as logical initial true no-undo.

    if guiautor.cd-unidade-carteira <> 004 then do:

        find last b-guiautor 
             where rowid(b-guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
             exclusive-lock no-error.

        if available b-guiautor then 
        do:
    
            if (b-guiautor.u-dec-2 > 0) then 
            do: 
                assign b-guiautor.aa-guia-atendimento-ant = integer(substring(string(b-guiautor.u-dec-2),1,4))
                       b-guiautor.nr-guia-atendimento-ant = integer(substring(string(b-guiautor.u-dec-2),5)).
    
                for each tmp-cpc-at1000-saida 
                    exclusive-lock: 
                     
                     delete tmp-cpc-at1000-saida. 
                end.

                create tmp-cpc-at1000-saida.
                assign tmp-cpc-at1000-saida.lg-undo-retry       = no
                       tmp-cpc-at1000-saida.lg-comunica-scs     = no
                       tmp-cpc-at1000-saida.lg-cria-guia        = yes
                       tmp-cpc-at1000-saida.ds-mensagem         = ""
                       tmp-cpc-at1000-saida.ds-observ-guia      = "cpc-at1000-prComunicaPedidoDeComplemento1"
                       tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira.

                return.
            end.

        end.
    end.
end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prComunica:
    if guiautor.cd-unidade-carteira <> 004 then
    do:
        if guiautor.ds-mens-intercambio <> "" and guiautor.in-liberado-guia = '10' then
            run prProcValorBaixo.
        else
        do:
            if guiautor.ds-observacao = "" then
            do:
                create tmp-cpc-at1000-saida.
                assign tmp-cpc-at1000-saida.lg-undo-retry       = no
                       tmp-cpc-at1000-saida.lg-comunica-scs     = no
                       tmp-cpc-at1000-saida.lg-cria-guia        = yes
                       tmp-cpc-at1000-saida.ds-mensagem         = ""
                       tmp-cpc-at1000-saida.ds-observ-guia      = "cpc-at1000-prcomunica1"
                       tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira.
    
                if guiautor.in-liberado-guias = '10' then assign tmp-cpc-at1000-saida.lg-comunica-scs = yes.
            end.
            else
            do:
                create tmp-cpc-at1000-saida.
                assign tmp-cpc-at1000-saida.lg-undo-retry       = no
                       tmp-cpc-at1000-saida.lg-comunica-scs     = no
                       tmp-cpc-at1000-saida.lg-cria-guia        = yes
                       tmp-cpc-at1000-saida.ds-mensagem         = ""
                       tmp-cpc-at1000-saida.ds-observ-guia      = "cpc-at1000-prcomunica2"
                       tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira.

                if guiautor.in-liberado-guias = '1' or guiautor.in-liberado-guias = '2' 
                 then assign tmp-cpc-at1000-saida.lg-comunica-scs = no.
            end.
        end.
    end.
end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prVerificaSeComunica:

    def var lg_comunica         as log init yes no-undo.

    if not avail guiautor then return.
    if guiautor.cd-unidade-carteira = 004 then return.
    if guiautor.dt-emissao-guia < DATE("01/01/2017") then return.

    find first out-uni
        use-index out-uni1
            where out-uni.cd-unidade          = guiautor.cd-unidade-carteira
              and out-uni.cd-carteira-usuario = guiautor.cd-carteira-usuario
              no-lock no-error.

               if not avail out-uni then return.
               
               find first unimed use-index unimed1
                    where unimed.cd-unimed    = out-uni.cd-unidade
                    no-lock no-error.
               
                    if not avail unimed then return.
                    
                    if not unimed.lg-possui-interc-eletronico then return.
                    
                    lg_comunica = yes.

                    if fnAutAutom(guiautor.cd-tipo-guia, 0) then /* Autoriza todas guias do tipo de guia */
                       lg_comunica = no.
                    else
                    do:
                        for each procguia use-index procgui1
                           where procguia.cd-unidade             = guiautor.cd-unidade
                             and procguia.aa-guia-atendimento    = guiautor.aa-guia-atendimento
                             and procguia.nr-guia-atendimento    = guiautor.nr-guia-atendimento
                             no-lock:
                    
                            lg_comunica = no.

                            if not fnAutAutom(guiautor.cd-tipo-guia, (procguia.cd-esp-amb * 1000000 + procguia.cd-grupo-proc-amb * 10000 + procguia.cd-procedimento * 10 + procguia.dv-procedimento * 1)) then
                            do:
                                lg_comunica = yes.
                                leave.
                            end.
                        end.
                    
                        if not lg_comunica then /* Todos procedimentos estÆo parametrizados para autorizar automaticamente */
                            run prCriaSaida("2").
                        else
                        do:
                            if guiautor.u-log-2 then
                                lg_comunica = no.
                            else
                            do:

                                find first tip-guia use-index tip-gui1
                                     where tip-guia.cd-tipo-guia   = guiautor.cd-tipo-guia
                                       and tip-guia.u-log-2        = yes
                                       no-lock no-error.
                        
                                if avail tip-guia then
                                    lg_comunica = no.
                                else
                                do:
                                    for each procguia use-index procgui1
                                       where procguia.cd-unidade             = guiautor.cd-unidade
                                         and procguia.aa-guia-atendimento    = guiautor.aa-guia-atendimento
                                         and procguia.nr-guia-atendimento    = guiautor.nr-guia-atendimento
                                         no-lock,
                        
                                        first ambproce use-index ambproc1
                                          where ambproce.cd-esp-amb         = procguia.cd-esp-amb       
                                            and ambproce.cd-grupo-proc-amb  = procguia.cd-grupo-proc-amb
                                            and ambproce.cd-procedimento    = procguia.cd-procedimento  
                                            and ambproce.dv-procedimento    = procguia.dv-procedimento  
                                            and ambproce.u-log-3            = yes
                                            no-lock:

                                            lg_comunica = no.
                                    end.
                                end.
                            end.
                    
                            for each procguia of guiautor 
                               where procguia.int-2 > 0 
                               no-lock:

                                lg_comunica = no.
                                leave.

                            end.
                        
                            if not lg_comunica then /* NÆo comunicar */
                                run prCriaSaida("1").
                            else
                                run prCriaSaida("10").
                        end.
                    end.
end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prCriaSaida:
    def input param inStatus            like guiautor.in-liberado-guias no-undo.

    create tmp-cpc-at1000-saida.
    assign tmp-cpc-at1000-saida.lg-undo-retry       = no
           tmp-cpc-at1000-saida.lg-comunica-scs     = no
           tmp-cpc-at1000-saida.lg-cria-guia        = yes
           tmp-cpc-at1000-saida.ds-mensagem         = ""
           tmp-cpc-at1000-saida.ds-observ-guia      = "cpc-at1000-prcriasaida"
           tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira
           tmp-cpc-at1000-saida.in-liberado-guias   = inStatus
           tmp-cpc-at1000-saida.cd-local-autorizacao    = tmp-cpc-at1000-entrada.cd-local-autorizacao. 

end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prRegrasAt1000:
    if tmp-cpc-at1000-entrada.cd-unidade-carteira <> 004 then
    do:
        run alimenta-tmp-movto-propria.
        
        find first assotgcl use-index assotgc3
             where assotgcl.cd-tipo-guia = tmp-cpc-at1000-entrada.cd-tipo-guia
               and assotgcl.cd-unidade   = 004
               and assotgcl.cd-prestador = 004 
               no-lock no-error.    
        
        if avail assotgcl then  /*SADT*/
        do:  
            if (assotgcl.in-classe-nota = 2 
             or assotgcl.in-classe-nota = 3 
             or assotgcl.in-classe-nota = 5 
             or assotgcl.in-classe-nota = 8)then 
             do:
                lg-sadt = yes.
             end.
        end.
        
       /* IF lg-sadt = YES 
         AND NOT( CAN-FIND (FIRST tmp-movtos-propria WHERE tmp-movtos-propria.lg-glosa = yes) ) THEN 
              RUN prCriaSaida("2"). 
         ELSE RUN prCriaSaida("10").*/

    end.
end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure alimenta-tmp-movto-propria:

    def var cd-proc-str as char no-undo.
    
    for each tmp-cpc-at1000-movtos no-lock:

        create tmp-movtos-propria.
        assign tmp-movtos-propria.cd-procedimento = tmp-cpc-at1000-movtos.cd-procedimento
               tmp-movtos-propria.cd-tipo-insumo  = tmp-cpc-at1000-movtos.cd-tipo-insumo 
               tmp-movtos-propria.cd-insumo       = tmp-cpc-at1000-movtos.cd-insumo 
               tmp-movtos-propria.cd-unidade      = tmp-cpc-at1000-movtos.cd-unidade 
               tmp-movtos-propria.cd-prestador    = tmp-cpc-at1000-movtos.cd-prestador. 
               /*tmp-movtos-propria.lg-glosa        = tmp-cpc-at1000-movtos.lg-glosa.*/

        assign cd-proc-str = string(tmp-cpc-at1000-movtos.cd-procedimento).

        find first procguia use-index procgui2
             where procguia.cd-unidade          = guiautor.cd-unidade
               and procguia.aa-guia-atendimento = guiautor.aa-guia-atendimento
               and procguia.nr-guia-atendimento = guiautor.nr-guia-atendimento
               and procguia.cd-esp-amb          = INT(substring(cd-proc-str, 1, 2))
               and procguia.cd-grupo-proc-amb   = INT(substring(cd-proc-str, 3, 2))
               and procguia.cd-procedimento     = INT(substring(cd-proc-str, 5, 3))
               and procguia.dv-procedimento     = INT(substring(cd-proc-str, 8, 1)) 
               no-lock no-error.
        
               if avail procguia then
               do:
                assign tmp-movtos-propria.cd-modulo        = procguia.cd-modulo 
                       tmp-movtos-propria.nr-processo      = procguia.nr-processo 
                       tmp-movtos-propria.nr-seq-digitacao = procguia.nr-seq-digitacao 
                       tmp-movtos-propria.qt-movto         = procguia.qt-procedimento.
               end.
               else do:
                   find first insuguia use-index insugui2
                        where insuguia.cd-unidade          = guiautor.cd-unidade
                          and insuguia.aa-guia-atendimento = guiautor.aa-guia-atendimento
                          and insuguia.nr-guia-atendimento = guiautor.nr-guia-atendimento
                          and insuguia.cd-tipo-insumo      = tmp-cpc-at1000-movtos.cd-tipo-insumo
                          and insuguia.cd-insumo           = tmp-cpc-at1000-movtos.cd-insumo 
                          no-lock no-error.

                          if avail insuguia then 
                          do:
                             assign tmp-movtos-propria.cd-modulo        = insuguia.cd-modulo 
                                    tmp-movtos-propria.nr-processo      = insuguia.nr-processo 
                                    tmp-movtos-propria.nr-seq-digitacao = insuguia.nr-seq-digitacao 
                                    tmp-movtos-propria.qt-movto         = insuguia.qt-insumo.
                          end.
               end.
    end.                                                                                   

end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

procedure prProcValorBaixo:

    def var lg_achou                as log no-undo.
    def var inStatus                like guiautor.in-liberado-guias no-undo.

    find first unimed use-index unimed1
         where unimed.cd-unimed    = guiautor.cd-unidade-carteira
         no-lock no-error.
    
    if not avail unimed then return.
    
    if not unimed.lg-possui-interc-eletronico then return.

    find first unicamco use-index unicamc1
         where unicamco.cd-unidade = guiautor.cd-unidade-carteira
           and unicamco.dt-limite >= today
           no-lock no-error.

    /* Verifica se tem pelo menos um procedimento na guia que precisa de autoriza‡Æo da unidade */
    lg_achou = no.
    
    if can-find (last insuguia use-index insugui1
          where insuguia.cd-unidade             = guiautor.cd-unidade         
            and insuguia.aa-guia-atendimento    = guiautor.aa-guia-atendimento
            and insuguia.nr-guia-atendimento    = guiautor.nr-guia-atendimento)
        then return.

       for each procguia use-index procgui1
          where procguia.cd-unidade             = guiautor.cd-unidade
            and procguia.aa-guia-atendimento    = guiautor.aa-guia-atendimento
            and procguia.nr-guia-atendimento    = guiautor.nr-guia-atendimento
        no-lock,

        first pl-mo-am use-index pl-mo-am1
          where pl-mo-am.cd-modalidade  = unicamco.cd-modalidade
            and pl-mo-am.cd-plano       = unicamco.cd-plano
            and pl-mo-am.cd-tipo-plano  = unicamco.cd-tipo-plano
            and pl-mo-am.cd-modulo      = procguia.cd-modulo
            and pl-mo-am.cd-amb         = procguia.cd-esp-amb * 1000000 + procguia.cd-grupo-proc-amb * 10000 + procguia.cd-procedimento * 10 + procguia.dv-procedimento
            and pl-mo-am.lg-aut-unimed  = no
            and pl-mo-am.cd-modulo      >= 110
            and pl-mo-am.cd-modulo      <= 310
            no-lock:

        lg_achou = yes.

        leave.
    end.

    if lg_achou then
    do:
        find first preserv use-index preserv1
             where preserv.cd-unidade      = guiautor.cd-unidade-solicitante
               and preserv.cd-prestador    = guiautor.cd-prestador-solicitante
               no-lock no-error.

        if not avail preserv then leave.

        inStatus = guiautor.in-liberado-guias.

        open query qrout-uni 
        for each out-uni 
           where out-uni.cd-unidade          = guiautor.cd-unidade-carteira 
             and out-uni.cd-carteira-usuario = guiautor.cd-carteira-usuario 
             no-lock.

             get first qrout-uni.
             do while AVAIL(out-uni):

            /* Regra para prestadores jur¡dicos (grupo de hospitais), se for urgˆncia, autoriza */
            if ((preserv.cd-grupo-prestador >= 30 and preserv.cd-grupo-prestador <= 36) or preserv.cd-grupo-prestador = 39) then
            do:
                if out-uni.dt-validade-cart >= today then inStatus = '2'.
            end.
            else
            do:
                if can-do("0075,0078,0118,0281", string(out-uni.cd-unidade, "9999")) then
                do:
                    if (out-uni.int-5 = 0 
                     or out-uni.int-5 = 1 
                     or out-uni.int-5 = 3) 
                    and out-uni.dt-validade-cart >= today then inStatus = '2'.
                    else inStatus = '8'.
                end.
                else
                do:
                    if (out-uni.int-5 = 0 
                     or out-uni.int-5 = 1) 
                    and out-uni.dt-validade-cart >= today then inStatus = '2'.
                    else inStatus = '8'.
                end.
            end.

            get next qrout-uni.
        end.

        close query qrout-uni.

        if inStatus <> guiautor.in-liberado-guias then
        do:
            find first guiautor 
                 where rowid(guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
                 exclusive-lock no-error.

            assign guiautor.in-liberado-guias      = inStatus
                   guiautor.dt-atualizacao         = today.
            
            create tmp-cpc-at1000-saida.
            assign tmp-cpc-at1000-saida.lg-undo-retry       = no
                   tmp-cpc-at1000-saida.lg-comunica-scs     = no
                   tmp-cpc-at1000-saida.lg-cria-guia        = yes
                   tmp-cpc-at1000-saida.ds-mensagem         = ""
                   tmp-cpc-at1000-saida.ds-observ-guia      = "prProcValorBaixo"
                   tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira.
                   tmp-cpc-at1000-saida.in-liberado-guias   = inStatus.
                   
        end.
    end.
end procedure.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/

function fnAutAutom returns log(input cdTipoGuia as int, input cdProc as int):

    if can-find(first gpTpGuiaXProc
                use-index gpTpGuiaXProc1
                    where gpTpGuiaXProc.cdTpGuia          = cdTipoGuia
                      and gpTpGuiaXProc.cdProcedimento    = cdProc
                      no-lock) then
        return yes.

    return no.
end.

/***************************************************************************************************************************************************************/
/***************************************************************************************************************************************************************/
