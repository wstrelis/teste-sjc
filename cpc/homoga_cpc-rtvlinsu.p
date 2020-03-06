/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i CPC/CPC-RTVLINSU.P 1.02.00.101T1}  /*** 010002 ***/
/* ***************************************************************************
    Programa .....: cpc-rtvlinsu.p
    Data .........: 14 de Marco de 2008
    Sistema ......: RC - Revisao de Contas Medicas
    Empresa ......: DATASUL Saude  
    Cliente ......: UNIMED Sao Jose dos Campos
    Programador ..: Rudah Billig
    Objetivo .....: Logica de CPC no rtvlinsu.p
* ---------------------------------------------------------------------------- */
/* ------------------------------------ Definicao das Variaveis Auxiliares -- */
def var c-versao                        as char                       no-undo.
assign c-versao = "7.00.000".
{hdp/hdlog.i}  /* -- Include necessario para log´s do Sistema nao retirar --- */

/* ------------------------------------ Definicao das Tabelas Temporarias --- */
{cpc/cpc-rtvlinsu.i} 
{rtp/rtvlinsu.i}
/* ---------------------------- Definicao dos Parametros de Entrada/Saida --- */

/* DEFINE TEMP-TABLE tmp-cpc-rtvlinsu-entrada NO-UNDO                                                    */
/*     FIELD in-tipo-valori                    as char format "x(03)"                                    */
/*     FIELD in-evento-programa                as char format "x(10)"                                    */
/*     FIELD nm-ponto-chamada-cpc              as char format "x(15)"                                    */
/*     FIELD cd-tab-preco-proc                 like prepadin.cd-tab-preco-proc                           */
/*     FIELD cd-unidade-prestador              like preserv.cd-unidade                                   */
/*     FIELD cd-prestador                      like preserv.cd-prestador                                 */
/*     FIELD cd-tipo-insumo                    like prepadin.cd-tipo-insumo                              */
/*     FIELD cd-insumo                         like prepadin.cd-insumo                                   */
/*     FIELD dt-base-valor                     like moviproc.dt-base-valor                               */
/*     FIELD r-proposta                        as rowid                                                  */
/*     FIELD r-unicamco                        as rowid                                                  */
/*     FIELD cd-modulo                         like mod-cob.cd-modulo                                    */
/*     FIELD cd-local-atendimento              like locaaten.cd-local-atendimento                        */
/*     FIELD qt-insumo                         like mov-insu.qt-insumo                                   */
/*     FIELD vl-insumo                         like mov-insu.vl-insumo                                   */
/*     FIELD cd-grupo-prestador                like moccolat.cd-grupo-prestador                          */
/*     FIELD cd-especialidade                  like moccolat.cd-especialid                               */
/*     FIELD cd-moeda-honorarios               like moccolat.mo-codigo                                   */
/*     FIELD qt-moeda-insumo                   like prepadin.qt-moeda-insumo                             */
/*     FIELD lg-manual                         like prepadin.lg-manual                                   */
/*     FIELD in-local-qtd                      as char                                                   */
/*     FIELD r-preinpr                         as rowid                                                  */
/*     FIELD nr-fator-multiplicador            like presinsu.nr-fator-multiplicador                      */
/*     FIELD vl-cotacao                        like dzcotac.cota-media. /* Valor da cota‡Æo da moeda. */ */
/*                                                                                                       */
/*                                                                                                       */
/* DEFINE TEMP-TABLE tmp-cpc-rtvlinsu-saida NO-UNDO                                                      */
/*     FIELD lg-erro                           as log                                                    */
/*     FIELD ds-mensagem                       as char format "x(75)"                                    */
/*     FIELD pc-acres-desc                     as dec                                                    */
/*     FIELD lg-tipo-aplicacao                 as log                                                    */
/*     FIELD qt-moeda-insumo                   like prepadin.qt-moeda-insumo                             */
/*     FIELD vl-insumo                         like mov-insu.vl-insumo                                   */
/*     FIELD lg-manual                         like prepadin.lg-manual                                   */
/*     FIELD lg-achou-regra                    as log                                                    */
/*     FIELD nr-cotacao                        like moccolat.nr-cotacao                                  */
/*     FIELD in-local-qtd                      as char format "x(20)"                                    */
/*     FIELD lg-acres-desc                     as log                                                    */
/*     FIELD nr-fator-multiplicador            like presinsu.nr-fator-multiplicador.                     */


def input  parameter table for tmp-cpc-rtvlinsu-entrada.
def output parameter table for tmp-cpc-rtvlinsu-saida.
def input  parameter table for tmp-rtvlinsu-entrada.

find first tmp-cpc-rtvlinsu-entrada no-lock no-error.

if not avail tmp-cpc-rtvlinsu-entrada
then do:
    create tmp-cpc-rtvlinsu-saida.
    assign tmp-cpc-rtvlinsu-saida.lg-erro = yes
           tmp-cpc-rtvlinsu-saida.ds-mensagem = "Tabela temporaria de entrada da cpc-rtvlinsu nao encontrada.".
    return.
end.


/* Incorpora a quantidade do insumo somente no final do calculo para resolver o arredondamento */
if   tmp-cpc-rtvlinsu-entrada.nm-ponto-chamada-cpc      = "PRECO-MEDIO" 
and (   tmp-cpc-rtvlinsu-entrada.in-evento-programa     = "ARRED" 
     or tmp-cpc-rtvlinsu-entrada.in-evento-programa     = "") 
then do:
    
    if tmp-cpc-rtvlinsu-entrada.vl-cotacao = 0 
    then do:
        assign tmp-cpc-rtvlinsu-entrada.vl-cotacao = 1.    
    end.

    if tmp-cpc-rtvlinsu-entrada.in-tipo-valori  = "COB" 
    then do:    
        create tmp-cpc-rtvlinsu-saida.
        assign tmp-cpc-rtvlinsu-saida.vl-insumo = tmp-cpc-rtvlinsu-entrada.qt-moeda-insumo * tmp-cpc-rtvlinsu-entrada.nr-fator-multiplicador.
    end.
    else do:    
        create tmp-cpc-rtvlinsu-saida.
        assign tmp-cpc-rtvlinsu-saida.vl-insumo = tmp-cpc-rtvlinsu-entrada.qt-moeda-insumo * tmp-cpc-rtvlinsu-entrada.vl-cotacao * tmp-cpc-rtvlinsu-entrada.nr-fator-multiplicador.

        if tmp-cpc-rtvlinsu-entrada.lg-existe-regra-pc 
        then do: 			                                                                                                                                                         
            if tmp-cpc-rtvlinsu-entrada.lg-tipo-aplicacao  
            then do:                                                                                                             
                assign  tmp-cpc-rtvlinsu-saida.vl-insumo  = tmp-cpc-rtvlinsu-saida.vl-insumo + (tmp-cpc-rtvlinsu-saida.vl-insumo * tmp-cpc-rtvlinsu-entrada.pc-aplicacao / 100).
            end.
            else do:
                assign  tmp-cpc-rtvlinsu-saida.vl-insumo  = tmp-cpc-rtvlinsu-saida.vl-insumo - (tmp-cpc-rtvlinsu-saida.vl-insumo * tmp-cpc-rtvlinsu-entrada.pc-aplicacao / 100).
            end.
        end.
        
        find first paramecp no-lock.
        
        if tmp-cpc-rtvlinsu-entrada.cd-unidade-prestador = paramecp.cd-unimed
        and available tmp-cpc-rtvlinsu-saida
        then do:
            assign tmp-cpc-rtvlinsu-saida.vl-insumo = round (tmp-cpc-rtvlinsu-saida.vl-insumo, 2).
        end.
    end.
    

end.
/* ----------------------------------------------------------------------------------------------------------------- */
/* --------------------------------------------------------------------------------------------------------- EOF --- */
/* ----------------------------------------------------------------------------------------------------------------- */

/* 
08/03/2016 - Denis Kazuo

Tabela de entrada tmp-cpc-rtvlisu-entrada 
def temp-table tmp-cpc-rtvlinsu-entrada no-undo
 FIELD in-tipo-valori           as char format "x(03)"                                                                                            
 FIELD in-evento-programa       as char format "x(10)"
 FIELD nm-ponto-chamada-cpc     as char format "x(15)"
 FIELD cd-tab-preco-proc        like prepadin.cd-tab-preco-proc                                              
 FIELD cd-unidade-prestador     like preserv.cd-unidade                                                      
 FIELD cd-prestador             like preserv.cd-prestador                                                    
 FIELD cd-tipo-insumo           like prepadin.cd-tipo-insumo                                                 
 FIELD cd-insumo                like prepadin.cd-insumo                                                      
 FIELD dt-base-valor            like moviproc.dt-base-valor                                                  
 FIELD r-proposta               as rowid
 FIELD r-unicamco               as rowid
 FIELD cd-modulo                like mod-cob.cd-modulo
 FIELD cd-local-atendimento     like locaaten.cd-local-atendimento
 FIELD qt-insumo                like mov-insu.qt-insumo
 FIELD vl-insumo                like mov-insu.vl-insumo
 FIELD cd-grupo-prestador       like moccolat.cd-grupo-prestador
 FIELD cd-especialidade         like moccolat.cd-especialid
 FIELD cd-moeda-honorarios      like moccolat.mo-codigo
 FIELD qt-moeda-insumo          like prepadin.qt-moeda-insumo
 FIELD lg-manual                like prepadin.lg-manual
 FIELD in-local-qtd             as char
 FIELD r-preinpr                as rowid
 FIELD r-out-uni                as rowid
 FIELD cd-tab-medic-valori      like prepadin.cd-tab-preco-proc
 FIELD nr-fator-multiplicador   like presinsu.nr-fator-multiplicador.  
    
Defini‡Æo campo a campo da tabela de entrada
o	in-evento-programa - Evento do programa que chama a cpc-rtvlinsu.p. Os valores desse campo podem ser:
"	"INCLUI" 
o	nm-ponto-chamada-cpc - Sendo:
"	"PRECO-MEDIO"
"	"TRATA-PREINPR"
"	" TAB-PRECO-INSU "
"	"BLOQ-VAL-INSUMO"
?	"APOS-CALC-ACRDE"
"	"APOS-FAT-TPINSU"
o	in-tipo-valori - ;
o	cd-tab-preco-proc -  C¢digo da tabela de pre‡os;
o	cd-unidade-prestador -  C¢digo da unidade do prestador;
o	cd-prestador - C¢digo do prestador;
o	cd-tipo-insumo - C¢digo do tipo de insumo;
o	cd-insumo - C¢digo do insumo;
o	dt-base-valor - Data limite do movimento;
o	r-proposta - Rowid da tabela proposta;
o	r-unicamco - Rowid da tabela unicamco;
o	cd-modulo - C¢digo do m¢dulo;
o	cd-local-atendimento - C¢digo do local de atendimento;
o	qt-insumo - quantidade de insumos;
o	vl-insumo - Valor do insumo;
o	cd-grupo-prestador - C¢digo do grupo de prestadores;
o	cd-especialidade - C¢digo da especialidade;
o	cd-moeda-honorarios - C¢digo da moeda.
o	r-preinpr - rowid da tabela preinpr. 
o	nr-fator-multiplicador - fator multiplicador para o tipo de insumo.

Tabela de sa¡da tmp-cpc-rtvlinsu-saida
	FIELD lg-erro                  as log
    FIELD ds-mensagem              as char format "x(75)"
    FIELD pc-acres-desc            as dec
    FIELD lg-tipo-aplicacao        as log
    FIELD qt-moeda-insumo          like prepadin.qt-moeda-insumo
    FIELD vl-insumo                like mov-insu.vl-insumo
    FIELD lg-manual                like prepadin.lg-manual
    FIELD lg-achou-regra           as log
    FIELD nr-cotacao               like moccolat.nr-cotacao
    FIELD in-local-qtd             as char format "x(20)"
    FIELD lg-acres-desc            as log
    FIELD nr-fator-multiplicador   like presinsu.nr-fator-multiplicador.

Defini‡Æo campo a campo da tabela de sa¡da
o	lg-erro - Vari vel que controla se erros aconteceram dentro da CPC deve retornar SIM se erros aconteceram e NÇO se o processo foi conclu¡do por completo.
o	ds-mensagem - Deve conter mensagens de erro ou qualquer outro tipo de mensagem.
o	pc-acres-desc - Percentual de acrescimo e desconto.
o	lg-tipo-aplicacao - Campo l¢gico que retorna o tipo de aplica‡Æo.
o	qt-moeda-insumo - Quantidade da moeda do insumo.
o	vl-insumo - Valor do insumo.
o	lg-manual - Indica se insumo pode ser inclu¡do de forma manual.
o	lg-achou-regra - Indica se foi encontrado alguma regra de moeda ou de percentual.
o	nr-cotacao - Valor da cota‡Æo da moeda.
o	In-local-qtd - Retorna a origem da busca da tabela (PADRAO/PREST).
o	lg-acres-desc - Retorna se ser  considerado o valor de acr‚scimo/desconto do prestador. 
o	nr-fator-multiplicador - fator multiplicador para o tipo de insumo.

*/
