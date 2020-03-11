ALTERAÇÃO DA ANDREIA

dsadsadsadad


/******************************************************************************
    Programa .....: cpc-fp0711f.p
    Data .........: 26/12/2007
    Sistema ......:
    Empresa ......: DATASUL SAUDE
    Cliente ......: UNIMED Porto Alegre
    Programador ..: RAFAEL BONATTO
    Objetivo .....: Cpc com logica especifica do cliente
******************************************************************************/

{include/i-prgvrs.i CPCFONTES/CPC-fp0711f.P 1.02.00.002}  /*** 010002 ***/

/* ----------------------- DEFINICAO DAS TEMPORARIAS ----------------------- */
{cpc/cpc-fp0711f.i}  

/* -------- DECLARACAO DE VARIAVEIS COMPARTILHADAS COM PROGS. CHAMADORES --- */
{fpp/fp0711a.i4}

/*=================================================================================*/
define shared temp-table w-fateve no-undo     like fatueven.
/* ----------------------- TEMP-TABLE UTILIZADA PELOS VALORES POR BENEF. --- */
{fpp/fp0711a.i11 "shared"}

define variable c-versao              as character                                    no-undo.

assign  c-versao = "7.00.000".

{hdp/hdlog.i}   /* --- Include necessario para log's do Sistema --- */

define temp-table wk-evento-imposto no-undo
    field cd-evento     like fatueven.cd-evento
    field cd-imposto    like dzimposto.cd-imposto
    field vl-base       as decimal
    field pc-aliquota   like evenimp.pc-aliquota
    index cd-evento
          cd-imposto.


/* -------------------------------------------------- INICIO DO PROCESSO --- */
define input         parameter table for tmp-cpc-fp0711f-entrada.
define input-output  parameter table for wk-evento-imposto.
define output        parameter table for tmp-cpc-fp0711f-saida.

find first tmp-cpc-fp0711f-entrada no-lock no-error.

if   not available tmp-cpc-fp0711f-entrada
then return.

/* ------------------------------------------------------------ WAL-MART --- */
case tmp-cpc-fp0711f-entrada.nm-ponto-chamada:

  when "CRIA-EVEN-PROG"
  then do:
         create tmp-cpc-fp0711f-saida.                  
         assign tmp-cpc-fp0711f-saida.vl-total-nota = tmp-cpc-fp0711f-entrada.vl-total-nota.
         
              
         /* ler todos os benefs do termo que tem devolucao RN412*/
             
         for each event-progdo-bnfciar where event-progdo-bnfciar.cd-modalidade = cd-modalidade-aux                          
                                         and event-progdo-bnfciar.nr-ter-adesao = nr-ter-ade-aux
                                         and event-progdo-bnfciar.aa-referencia = aa-ref-aux
                                         and event-progdo-bnfciar.mm-referencia = mm-ref-aux
                                         and (event-progdo-bnfciar.cd-evento    = 621 /*Evento da RN 412*/
                                                  or event-progdo-bnfciar.cd-evento = 622
                                                  or event-progdo-bnfciar.cd-evento = 623
                                                  or event-progdo-bnfciar.cd-evento = 624)
                                         and event-progdo-bnfciar.nr-sequencia  = 0 no-lock: /* nr-sequencia = 0 indica que ainda nao foi faturado */
                                             
              assign cd-evento-aux = event-progdo-bnfciar.cd-evento  
                     vl-evento-aux = event-progdo-bnfciar.vl-evento.   
                        
                                             
              run calculo-programado-valor. /* Calcula e grava nas tabelas do sistema os valores*/    
                                             
           end.  
      end.
 end case.     
      
/* ------------------------------ ROTINA PARA EVENTOS PROGRAMADOS (VALOR) --- */
procedure calculo-programado-valor:
    define variable nr-idade-usuario            as   integer                        no-undo.
    define variable lg-erro-aux                 as   logical                        no-undo.
    define variable nr-faixa-usu-prog-aux       like teadgrpa.nr-faixa-etaria       no-undo.
    define variable cd-contrat-aux              like vlbenef.cd-contratante         no-undo.    
    define variable cd-contrat-origem-aux       like vlbenef.cd-contratante-origem  no-undo.
    define variable tot-vl-prog-aux             like w-fateve.vl-evento             no-undo.
    define variable vl-total-benef-aux          like w-fateve.vl-evento             no-undo.
  
    find first usuario 
         where usuario.cd-modalidade    = cd-modalidade-aux
           and usuario.nr-ter-adesao    = nr-ter-ade-aux
           and usuario.cd-usuario       = event-progdo-bnfciar.cd-usuario 
               no-lock no-error.
                          
 if not available usuario 
 then do:
         assign tmp-cpc-fp0711f-saida.lg-undo-retry    = yes
                tmp-cpc-fp0711f-saida.ds-mensagem-erro = "Usuario nao Cadastrado".
            
         return.  
    end. 

 find first propost where propost.cd-modalidade = cd-modalidade-aux
                      and propost.nr-ter-adesao = nr-ter-ade-aux no-lock no-error.
                           
 if not available propost
 then do:
         assign tmp-cpc-fp0711f-saida.lg-undo-retry    = yes
                tmp-cpc-fp0711f-saida.ds-mensagem-erro = "Proposta nao Cadastrada".
            
         return.  
    end.      

 find first ter-ade where ter-ade.cd-modalidade = cd-modalidade-aux
                      and ter-ade.nr-ter-adesao = nr-ter-ade-aux
                          no-lock no-error.
 if not available ter-ade 
 then do:
         assign tmp-cpc-fp0711f-saida.lg-undo-retry    = yes
                tmp-cpc-fp0711f-saida.ds-mensagem-erro = "Termo de Adesao nao Cadastrado".
            
         return.  
     end.
      
 case ter-ade.in-contratante-mensalidade:
   when 1 
   then do:
           find first contrat 
                where contrat.nr-insc-contratante = propost.nr-insc-contrat-origem 
                      no-lock no-error.
           if available contrat
           then assign cd-contrat-aux        = contrat.cd-contratante
                       cd-contrat-origem-aux = propost.nr-insc-contratante.
        end.
                                
   when 0 
   then assign cd-contrat-aux        = propost.cd-contratante
               cd-contrat-origem-aux = propost.nr-insc-contrat-origem.
 end case.
 
  
run rtp/rtidade.p (input  usuario.dt-nascimento,    
                   input  today,
                   output nr-idade-usuario,
                   output lg-erro-aux).
if lg-erro-aux
then do:
       assign tmp-cpc-fp0711f-saida.lg-undo-retry    = yes
              tmp-cpc-fp0711f-saida.ds-mensagem-erro = "Erro no calculo da Idade do Beneficiario".
       return.
    end.    
 
 
if propost.lg-faixa-etaria-esp
then do:
        for each teadgrpa where teadgrpa.cd-modalidade      = propost.cd-modalidade     
                            and teadgrpa.nr-proposta        = propost.nr-proposta       
                            and teadgrpa.cd-grau-parentesco = usuario.cd-grau-parentesco
                                no-lock.
                         
            if  teadgrpa.nr-idade-minima <= nr-idade-usuario 
            and teadgrpa.nr-idade-maxima >= nr-idade-usuario
            then assign nr-faixa-usu-prog-aux = teadgrpa.nr-faixa-etaria.
        end.                                 
     end.
 else do:
         for each pl-gr-pa  use-index pl-gr-pa1
            where pl-gr-pa.cd-modalidade      = propost.cd-modalidade     
              and pl-gr-pa.cd-plano           = propost.cd-plano          
              and pl-gr-pa.cd-tipo-plano      = propost.cd-tipo-plano     
              and pl-gr-pa.cd-grau-parentesco = usuario.cd-grau-parentesco
                  no-lock.
                               
             if  pl-gr-pa.nr-idade-minima <= nr-idade-usuario 
             and pl-gr-pa.nr-idade-maxima >= nr-idade-usuario
             then assign nr-faixa-usu-prog-aux = pl-gr-pa.nr-faixa-etaria.
         end.
       end. 
 

find first w-vlbenef where w-vlbenef.cd-modalidade       = cd-modalidade-aux                 
                     and w-vlbenef.cd-contratante        = cd-contrat-aux                
                     and w-vlbenef.cd-contratante-origem = cd-contrat-origem-aux        
                     and w-vlbenef.nr-ter-adesao         = nr-ter-ade-aux             
                     and w-vlbenef.aa-referencia         = aa-ref-aux                        
                     and w-vlbenef.mm-referencia         = mm-ref-aux                        
                     and w-vlbenef.cd-evento             = cd-evento-aux /*VER PRA PEGAR DA TIPELEVEN*/
                     and w-vlbenef.cd-usuario            = usuario.cd-usuario no-lock no-error.
                     
if not available w-vlbenef
then do:     
       create   w-vlbenef.
       assign   w-vlbenef.cd-modalidade         = cd-modalidade-aux           
                w-vlbenef.cd-contratante        = cd-contrat-aux
                w-vlbenef.cd-contratante-origem = cd-contrat-origem-aux
                w-vlbenef.nr-ter-adesao         = nr-ter-ade-aux        
                w-vlbenef.aa-referencia         = aa-ref-aux                     
                w-vlbenef.mm-referencia         = mm-ref-aux                     
                w-vlbenef.nr-sequencia          = nr-sequencia-aux 
                w-vlbenef.cd-padrao-cobertura   = usuario.cd-padrao-cobertura   
                w-vlbenef.qt-fator-mult         = 1
                w-vlbenef.qt-fator-tr-faixa     = 1  
                w-vlbenef.qt-fator-contippl     = 1
                w-vlbenef.qt-fator-forpagtx     = 1
                w-vlbenef.cd-usuario            = usuario.cd-usuario
                w-vlbenef.nr-faixa-etaria       = nr-faixa-usu-prog-aux
                w-vlbenef.cd-grau-parentesco    = usuario.cd-grau-parentesco
                w-vlbenef.cd-evento             = cd-evento-aux
                w-vlbenef.cd-modulo             = 0
                w-vlbenef.vl-usuario            = vl-evento-aux * -1
                w-vlbenef.vl-total              = vl-evento-aux * -1
                w-vlbenef.pc-proporcional       = 1. 
       /*                        
       
       /*----cria vlbenef-----*/      
       create vlbenef.
       assign vlbenef.cd-modalidade         = cd-modalidade-aux           
              vlbenef.cd-contratante        = cd-contrat-aux
              vlbenef.cd-contratante-origem = cd-contrat-origem-aux
              vlbenef.nr-ter-adesao         = nr-ter-ade-aux        
              vlbenef.aa-referencia         = aa-ref-aux                     
              vlbenef.mm-referencia         = mm-ref-aux                     
              vlbenef.nr-sequencia          = nr-sequencia-aux               
              vlbenef.cd-usuario            = usuario.cd-usuario            
              vlbenef.cd-evento             = cd-evento-aux                
              vlbenef.cd-modulo             = 0         
              vlbenef.nr-faixa-etaria       = nr-faixa-usu-prog-aux
              vlbenef.cd-grau-parentesco    = usuario.cd-grau-parentesco
              vlbenef.vl-usuario            = vl-evento-aux   
              vlbenef.vl-total              = vl-evento-aux 
              vlbenef.cd-userid             = v_cod_usuar_corren          
              vlbenef.dt-atualizacao        = today
              vlbenef.char-1                = event-progdo-bnfciar.cod-livre-1. */
   end.
       
  /* /*------- atualiza tot-----------*/
   assign vl-total-benef-aux = 0.
   
   for each  vlbenef fields( vlbenef.cd-evento
                             vlbenef.vl-usuario ) 
        where vlbenef.cd-modalidade = cd-modalidade-aux
          and vlbenef.nr-ter-adesao = nr-ter-ade-aux
          and vlbenef.aa-referencia = aa-ref-aux
          and vlbenef.mm-referencia = mm-ref-aux
          and vlbenef.cd-usuario    = event-progdo-bnfciar.cd-usuario
              exclusive-lock:
                                       
         find evenfatu 
         where evenfatu.in-entidade = "FT"
           and evenfatu.cd-evento   = vlbenef.cd-evento
               no-lock no-error.
         if avail evenfatu
         then do:
                if evenfatu.lg-cred-deb
                then assign vl-total-benef-aux = vl-total-benef-aux + vlbenef.vl-usuario.
                else assign vl-total-benef-aux = vl-total-benef-aux - vlbenef.vl-usuario.
              end.
   end.
                                   
   find first vlbenef where vlbenef.cd-modalidade         = cd-modalidade-aux
                        and vlbenef.nr-ter-adesao         = nr-ter-ade-aux
                        and vlbenef.aa-referencia         = aa-ref-aux
                        and vlbenef.mm-referencia         = mm-ref-aux
                        and vlbenef.nr-sequencia          = nr-sequencia-aux
                        and vlbenef.cd-usuario            = event-progdo-bnfciar.cd-usuario
                            exclusive-lock no-error.
   if avail vlbenef 
   then assign vlbenef.vl-total = vl-total-benef-aux. */
   
   

  /* -----Busca conta evento 4---------------------*/
  find first  tipleven
         where tipleven.in-entidade    = "FT"
           and tipleven.cd-modalidade  = propost.cd-modalidade
           and tipleven.cd-plano       = propost.cd-plano
           and tipleven.cd-tipo-plano  = propost.cd-tipo-plano
           and tipleven.cd-forma-pagto = propost.cd-forma-pagto             
           and tipleven.cd-evento      = cd-evento-aux
           and tipleven.lg-ativo       = yes
           no-lock no-error.
   if not available tipleven
   then do:
          assign tmp-cpc-fp0711f-saida.lg-undo-retry    = yes
                 tmp-cpc-fp0711f-saida.ds-mensagem-erro = "Tipo Plano x Evento nao Cadastrado".
            
          return.  
      end.      
  /* ------------------------------------------ Conta Contabil --- */
  run rtp/rtct-contabeis.p(input  tipleven.cd-modalidade,
                           input  tipleven.cd-plano,
                           input  tipleven.cd-tipo-plano,
                           input  tipleven.cd-forma-pagto,
                           input  tipleven.in-entidade,
                           input  tipleven.cd-evento,
                           input  tipleven.cd-modulo,
                           input  year(tmp-cpc-fp0711f-entrada.dt-emissao-aux),
                           input  month(tmp-cpc-fp0711f-entrada.dt-emissao-aux),
                           input  0,
                           input  "",
                           input  ?,
                           input  propost.in-tipo-contratacao,
                           input 1,
                           output lg-ct-contabil-aux,
                           output ct-codigo-aux,
                           output sc-codigo-aux,
                           output ct-codigo-dif-aux,
                           output sc-codigo-dif-aux,
                           output ct-codigo-dif-neg-aux,
                           output sc-codigo-dif-neg-aux,
                           output lg-evencontde-aux) no-error.
   if error-status:error
   then do:
           assign tmp-cpc-fp0711f-saida.lg-undo-retry    = yes
                  tmp-cpc-fp0711f-saida.ds-mensagem-erro = "Conta Contabil nao Cadastrada".
            
           return.  
      end.                        


find first w-fateve where w-fateve.cd-modalidade   = cd-modalidade-aux
                      and w-fateve.nr-ter-adesao   = nr-ter-ade-aux
                      and w-fateve.aa-referencia   = aa-ref-aux
                      and w-fateve.mm-referencia   = mm-ref-aux
                      and w-fateve.nr-sequencia    = nr-sequencia-aux
                      and w-fateve.cd-evento       = cd-evento-aux
                              no-lock no-error.
if not available w-fateve
then do:   
       create w-fateve.
       assign w-fateve.cd-modalidade   = cd-modalidade-aux
              w-fateve.nr-ter-adesao   = nr-ter-ade-aux
              w-fateve.aa-referencia   = aa-ref-aux
              w-fateve.mm-referencia   = mm-ref-aux
              w-fateve.nr-sequencia    = nr-sequencia-aux
              w-fateve.cd-evento       = cd-evento-aux
              w-fateve.ct-codigo       = ct-codigo-aux
              w-fateve.sc-codigo       = sc-codigo-aux
              w-fateve.qt-evento       = event-progdo-bnfciar.qt-evento
              w-fateve.vl-evento       = vl-evento-aux
              w-fateve.lg-cred-deb     = no
              w-fateve.lg-destacado    = lg-destacado-aux
              w-fateve.lg-modulo       = lg-modulo-aux
              w-fateve.cd-userid       = v_cod_usuar_corren
              w-fateve.dt-atualizacao  = today.      

       case ter-ade.in-contratante-mensalidade:
            when 1
            then assign w-fateve.cd-contratante        = cd-contrat-aux
                        w-fateve.cd-contratante-origem = cd-contrat-origem-aux.
            when 0
            then assign w-fateve.cd-contratante        = cd-contrat-aux
                        w-fateve.cd-contratante-origem = cd-contrat-origem-aux.
       end case.
    end.  
else assign w-fateve.vl-evento = w-fateve.vl-evento + vl-evento-aux
            w-fateve.qt-evento = w-fateve.qt-evento + 1.      

assign tmp-cpc-fp0711f-saida.vl-total-nota = tmp-cpc-fp0711f-saida.vl-total-nota - vl-evento-aux.
    
end procedure.
     
           
      
