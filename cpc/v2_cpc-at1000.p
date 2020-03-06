{cpc/cpc-at1000.i}

define input  parameter table for tmp-cpc-at1000-entrada.
define input  parameter table for tmp-cpc-at1000-movtos.
define output parameter table for tmp-cpc-at1000-saida.

define variable c-versao        as character format "x(08)" no-undo.
assign c-versao = "7.01.000".

find first tmp-cpc-at1000-entrada no-lock no-error.

if not avail tmp-cpc-at1000-entrada
then do:
    create tmp-cpc-at1000-saida.
    assign tmp-cpc-at1000-saida.lg-undo-retry   = yes
           tmp-cpc-at1000-saida.ds-mensagem     = "Tabela de entrada da CPC-AT1000 n∆o foi informada".
    return.
end.


run ProcessaCPC.



/* ************************  Function Prototypes ********************** */
function AtendeRegraNaoTrafegar returns logical 
	(in-tipo-guia          as   integer) forward.

/* **********************  Internal Procedures  *********************** */

procedure PontoAntesEnviarIE:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    
    find first paramecp no-lock.

    find first guiautor no-lock
         where rowid (guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
                no-error.

    if not available guiautor
    then do:
        create tmp-cpc-at1000-saida.
        assign tmp-cpc-at1000-saida.lg-undo-retry   = yes
               tmp-cpc-at1000-saida.ds-mensagem     = substitute ("N∆o foi encontrada a guia com o rowid (&1)", tmp-cpc-at1000-entrada.nr-rowid-guiaautor).
        return.        
    end.
    
    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry       = no               
           tmp-cpc-at1000-saida.cd-unidade-carteira = guiautor.cd-unidade-carteira.        
    
    if guiautor.in-liberado-guias   = "9"
    then do:
        assign tmp-cpc-at1000-saida.cd-unidade-carteira = paramecp.cd-unimed.
    end.

end procedure.

procedure PontoAtualizaStatus:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/

    define variable lg-deixar-guia-auditoria            as   logical            no-undo.

    find first paramecp no-lock.
    
    find first guiautor no-lock
         where rowid (guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor
                no-error.

    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry       = no.               

    if not available guiautor
    then do:
        assign tmp-cpc-at1000-saida.lg-undo-retry   = yes
               tmp-cpc-at1000-saida.ds-mensagem     = substitute ("N∆o foi encontrada a guia com o rowid (&1)", tmp-cpc-at1000-entrada.nr-rowid-guiaautor).
        return.        
    end.
    
    message "casali -> situaá∆o guia: " + string (guiautor.in-liberado-guias).        
    tmp-cpc-at1000-saida.in-liberado-guias   = guiautor.in-liberado-guia.
           
    if guiautor.cd-unidade-carteira     = paramecp.cd-unimed
    then return.
    
    if  guiautor.ds-mens-intercambio   <> ""
    and guiautor.in-liberado-guias      = '10' /* PENDENTE LIBERACAO */
    then do:
        run VerificaRegraValorBaixoUrgencia.
    end.    

    for each procguia no-lock
       where procguia.cd-unidade            = guiautor.cd-unidade
         and procguia.aa-guia-atendimento   = guiautor.aa-guia-atendimento
         and procguia.nr-guia-atendimento   = guiautor.nr-guia-atendimento:

        if  procguia.cd-grupo-proc-amb  = 40
        and procguia.cd-esp-amb         = 10
        and procguia.cd-procedimento    = 103
        and procguia.dv-procedimento    = 7
        then do:
            assign lg-deixar-guia-auditoria = yes.
        end.                     
    end.
    
    for each insuguia no-lock    
       where insuguia.cd-unidade            = guiautor.cd-unidade
         and insuguia.aa-guia-atendimento   = guiautor.aa-guia-atendimento
         and insuguia.nr-guia-atendimento   = guiautor.nr-guia-atendimento:
             
    end.
               
    if lg-deixar-guia-auditoria
    then do:
        tmp-cpc-at1000-saida.in-liberado-guias  = "9".
    end.               
end procedure.

procedure PontoAutorizacaoAutomatica:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/    
    find first paramecp no-lock.
    
    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry           = no
           tmp-cpc-at1000-saida.ds-mensagem             = "".
    
    find first guiautor no-lock
         where rowid (guiautor) = tmp-cpc-at1000-entrada.nr-rowid-guiaautor 
               no-error.
               
    if not available guiautor 
    then return.
    
    assign tmp-cpc-at1000-saida.in-liberado-guias   = guiautor.in-liberado-guias.               
    
    if tmp-cpc-at1000-entrada.cd-unidade-carteira   = paramecp.cd-unimed
    then return.
    
    if AtendeRegraNaoTrafegar (guiautor.cd-tipo-guia)
    then do:
        assign tmp-cpc-at1000-saida.in-liberado-guias   = '10'.
    end.
    

end procedure.

procedure PontoConsisteMovtos:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    find first paramecp no-lock.
    
    create tmp-cpc-at1000-saida. 
    assign tmp-cpc-at1000-saida.lg-undo-retry           = no
           tmp-cpc-at1000-saida.lg-cria-guia            = yes
           tmp-cpc-at1000-saida.lg-comunica-scs         = yes
           tmp-cpc-at1000-saida.cd-local-autorizacao    = tmp-cpc-at1000-entrada.cd-local-autorizacao.               

    if tmp-cpc-at1000-entrada.cd-unidade-carteira   = paramecp.cd-unimed
    then return.
    
    if AtendeRegraNaoTrafegar (tmp-cpc-at1000-entrada.cd-tipo-guia)
    then do:
        assign tmp-cpc-at1000-saida.lg-comunica-scs = no
               tmp-cpc-at1000-saida.ds-observ-guia  = "CASALI >X>X> NAO TRAFEGOU POIS ACHEI PROCEDIMENTO 4101037".
    end.  
end procedure.

procedure ProcessaCPC:
/*------------------------------------------------------------------------------
 Purpose:
 Notes:
------------------------------------------------------------------------------*/
    message "Nome do ponto de chamada da CPC: " + tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc.
    
    if  tmp-cpc-at1000-entrada.in-evento-programa   = 'INCLUI'   
    and tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc = "CONSISTE-MOVTOS"
    then do:
        run PontoConsisteMovtos.
    end.    
    if  tmp-cpc-at1000-entrada.in-evento-programa   = 'INCLUI'   
    and tmp-cpc-at1000-entrada.nm-ponto-chamada-cpc = "APOS-AUTOR-AUTO"
    then do:
        run PontoAutorizacaoAutomatica.
    end.    
end procedure.


/* ************************  Function Implementations ***************** */

function AtendeRegraNaoTrafegar returns logical 
	(in-tipo-guia          as   integer):
/*------------------------------------------------------------------------------
 Purpose: Verifica se a guia atende a regra que n∆o deve ser trafegada. Tratativas que impeáam a regra  
          de trafegar deve ser inclu°das nesta funá∆o.
 Notes:
------------------------------------------------------------------------------*/	
    define variable result as logical no-undo.
    
    for each tmp-cpc-at1000-movtos no-lock:
        /* PROCEDIMENTOS */
        if tmp-cpc-at1000-movtos.cd-procedimento   <> 0
        then do:
            if can-find (first gpTpGuiaXProc
                     use-index gpTpGuiaXProc1
                         where gpTpGuiaXProc.cdTpGuia          = in-tipo-guia
                           and gpTpGuiaXProc.cdProcedimento    = tmp-cpc-at1000-movtos.cd-procedimento
                               no-lock) 
            or tmp-cpc-at1000-movtos.cd-procedimento    = 40101037
            then do:
                assign result   = yes.
                leave.
            end. 
        end.
        /* INSUMOS */
        else do:
        end.
    end.
		
		
    return result.


		
end function.
