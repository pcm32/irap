% =========================================================
% Copyright 2012-2015,  Nuno A. Fonseca (nuno dot fonseca at gmail dot com)
%
% This file is part of iRAP.
%
% This is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with iRAP.  If not, see <http://www.gnu.org/licenses/>.
%
%
%    $Id: scripts/irap Nuno Fonseca Sat Jan 5 20:56:39 2013$
% =========================================================


:-prolog_initialization(go).

% checks if a combination of parameters (Mapper, Quant, Norm, DE) is valid
% or
% produces a plot with all the possible paths

go:-
	unix(argv(Args)),
	handle_args(Args),
	halt.

handle_args([File]):-!,
		     start_graph(File).

handle_args([M,Q,N,D]):-!,
    (valid_combination([M,Q,N,D,none,no])->
     format("valid~n",[])
    ;
     format("invalid~n",[])
    ).
handle_args([M,Q,N,D,G]):-!,
    (valid_combination([M,Q,N,D,G,no])->
     format("valid~n",[])
    ;
     format("invalid~n",[])
    ).

handle_args([M,Q,N,D,G,StrandedData]):-!,
    (valid_combination([M,Q,N,D,G,StrandedData])->
     format("valid~n",[])
    ;
     format("invalid~n",[])
    ).

handle_args(_):-
    format("ERROR! usage: irap_paths [ FILENAME | Mapper Quant Norm DE | Mapper Quant Norm DE GSE StrandedData@{yes,no}]~n",[]).


valid_combination([Map,QR,QN,DE,GSE,Stranded]):-
    m(Map,_,_,S1),
    qr(QR,m(Map),_,S2),
    qn(QN,qr(QR),_,S3),
    !,
    (Stranded==yes->S1==stranded,stranded_ok(Stranded,S2),stranded_ok(Stranded,S3);true),
    de(DE,(qr(QR),qn(QN)),_),
    gse(GSE,de(DE),_).

stranded_ok(yes,stranded).
stranded_ok(yes,X):- not ground(X),!.
stranded_ok(no,_).


member(X,[X|_]).
member(X,[_|R]):-
    member(X,R).

% generate a graphviz file with all possible combinations
start_graph(File):-
	format('Generating graphviz file ~w~n',[File]),
	open(File,write,S),!,
	eraseall(r_graph_fd),
	recorda(r_graph_fd,S,_),
        graph_format('digraph { outputorder=edgesfirst;~n',[]),
        graph_format('overlap=scale;~n~n',[]),
%        graph_format('splines=ortho;~n~n',[]),
        graph_format('splines=polyline;~n~n',[]),
        graph_format('model=circuit;~n',[]),
        graph_format('rankdir=TB;~n',[]),
        graph_format('center=true;~n',[]),
%        graph_format('model=subset;~n',[]),
	save_nodes,
%	graph_format('cluster_m -> cluster_qr [style="invis"]~n',[]),
%	graph_format('cluster_qr -> cluster_qn [style="invis"]~n',[]),
%	graph_format('cluster_qn -> cluster_de [style="invis"]~n',[]),		
	save_edges,
	end_graph.
get_fd(FD):-
	recorded(r_graph_fd,FD,_).

end_graph:-
        graph_format('}~n',[]).

graph_format(A,B):-
	get_fd(FD),
        format(FD,A,B),
        !.

start_cluster(Type):-
        type2label(Type,Label,Style),
	atom_concat(['cluster_',Type],NTag),
	graph_format('subgraph ~w { ~n',[NTag]),
        graph_format('center=true;~n',[]),
	graph_format(' label=\"~w\";~n',[Label]),
	graph_format(' ~w~n',[Style]).

end_cluster:-
	graph_format('} ~n',[]).

type2label(m,'Mappers','style=filled; color=lightgrey;labeljust=r;').
type2label(qr, 'Quantification','style=filled; color=lightgrey;labeljust=r;').
type2label(qn,'Normalization','style=filled; color=lightgrey;labeljust=r;').
type2label(de, 'DE','style=filled; color=lightgrey;labeljust=r;').
type2label(gse, 'GSE','style=filled; color=lightgrey;labeljust=r;').

%node(+nodeType,NodeName,-Label,-Style)
node(m,N,N,'[color=salmon2,style=filled]'):-
    m(N,_,_,_Strand),
    not N==none.
node(qr,N,N,'[color=coral3,style=filled]'):-
    qr(N,_,_,_),
    not N==scripture,
    not N==basic,
    not N==none.
%node(qn,NDE,N,Style):-
%    qn(NDE,_,_),
%    atom_concat(['[color=cyan,style=filled,label=',NDE,']'],Style),
%    atom_concat([NDE,'_qn'],N).
node(de,DE,DE,Style):-
    de(DE,_,_),
    not DE==none,
    atom_concat(['[color=lightsteelblue1,style=filled,label=',DE,']'],Style).
node(gse,GSE,GSE,Style):-
    gse(GSE,_,_),
    not GSE==none,
    atom_concat(['[color=lightsteelblue1,style=filled,label=',GSE,']'],Style).



save_nodes:-
    (all_mappers(Ls),T=m;all_quant(Ls),T=qr;all_quant_norm(Ls),T=de;all_de(Ls),T=de;Ls=[piano],T=gse),
    (start_cluster(T);end_cluster,fail),
    graph_format('~w [style=invis]~n',[T]),
    format('Nodes: ~w: ~w~n',[T,Ls]),
    member(L,Ls),
    node(T,N,L,Attrs),
    graph_format('~w ~w;~n',[N,Attrs]),
    fail.
save_nodes.

save_edges:-
    all_mappers(Ls),
    all_quant(Qs),
    member(Map,Ls),
    member(QR,Qs),
    once(m(Map,_,_,_)),
    qr(QR,m(Map),_,_),
    not QR='none',
    not QR==scripture,
    not QR==basic,
    graph_format('~w -> ~w;~n',[Map,QR]),
    fail.

save_edges:-fail,
    all((QN1,QR1),(qr(QR1,_,_,_),qn(QN1,qr(QR1),_,_)),L),
    format('~w~n',L),
    member((QN,QR),L),
    qn(QN,qr(QR),_,_),
    once(node(qn,QN,QNL,_)),
    once(node(qr,QR,QRL,_,_)),
    not QNL='none',
    not QRL='none',
    graph_format('~w -> ~w;~n',[QRL,QNL]),
    fail.

save_edges:-fail,
    all((DE1,QR1,QN1),(qr(QR1,_,_,_),qn(QN1,qr(QR1),_),de(DE1,(_,(qr(QR1),qn(QN1))),_)),L),
    member((DE,QR,QN),L),
    de(DE,(qr(QR),qn(QN)),_),
    graph_format('~w -> ~w;~n',[QR,DE]),
    fail.


save_edges:-
    all_quant(Qs),
    all_de(DEs),
    member(QR,Qs),
    not QR=='basic',
    not QR=='none',
    member(DE,DEs),
    not DE=='none',
    once(qr(QR,_,_,_)),
    once(de(DE,(qr(QR),_),_)),
    graph_format('~w -> ~w;~n',[QR,DE]),
    fail.

save_edges:-
    GSEs=[piano],
    all_de(DEs),
    member(GSE,GSEs),
    not GSE=='none',
    member(DE,DEs),
    not DE=='none',
    once(de(DE,_,_)),
    once(gse(GSE,de(DE),_)),
    graph_format('~w -> ~w;~n',[DE,GSE]),
    fail.

save_edges:-
%    member(T,[m,qr,de,gse]),
    graph_format('m -> qr -> de -> gse [style=invis,weight=100];~n',[]),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%reference(genome).
%reference(transcriptome).
%junctions

% mapper,prev.dependency,note,strandeddata
m('tophat1',_,'',stranded).
m('tophat2',_,'',stranded).
m('smalt',_,'',no).
m('gsnap',_,'',no).
m('soapsplice',_,'',no).
m('bwa1',_,'',no).
m('bwa2',_,'',no).
m('bowtie1',_,'',no).
m('bowtie2',_,'',no).
m('gem',_,'',no).
%m('gems',_,'').%RNA-version
m('star',_,'',no).
m('osa',_,'',no).
m('mapsplice',_,'',no).

all_mappers(X):-all(M,m(M,_,_,_),X).
all_quant([htseq1,htseq2,basic,flux_cap,cufflinks1,cufflinks2,cufflinks1_nd,cufflinks2_nd,nurd,stringtie,stringtie_nd]).
all_quant_norm([flux_cap,cufflinks1,cufflinks2,cufflinks1_nd,cufflinks2_nd,none,deseq,stringtie,stringtie_nd]).
all_de([deseq,edger,voom,cuffdiff1,cuffdiff2,cuffdiff1_nd,cuffdiff2_nd,deseq2,none]).

qr('htseq1',m(M),'Only requires the NH flag defined',stranded):-m(M,_,_,_S).
qr('htseq2',m(M),'Only requires the NH flag defined',stranded):-m(M,_,_,_S).
qr('basic',m(M),'',S):-m(M,_,_,S).
qr('cufflinks1',m(M),'BAM flags...',stranded):-m(M,_,_,_S),not member(M,[soapsplice]).
qr('cufflinks1_nd',m(M),'BAM flags...',stranded):-m(M,_,_,_S),not member(M,[soapsplice]).
qr('cufflinks2',m(M),'BAM flags...',stranded):-m(M,_,_,_S),not member(M,[soapsplice]).
qr('cufflinks2_nd',m(M),'BAM flags...',stranded):-m(M,_,_,_S),not member(M,[soapsplice]).
qr('stringtie',m(M),'BAM flags...',stranded):-m(M,_,_,_S),not member(M,[soapsplice]).
qr('stringtie_nd',m(M),'BAM flags...',stranded):-m(M,_,_,_S),not member(M,[soapsplice]).
qr('flux_cap',m(M),'',no):-m(M,_,_,_S).
qr('scripture',m(M),'',no):-m(M,_,_,_S).
qr('nurd',m(M),'',no):-m(M,_,_,_S).
%qr('ireckon',m(M),''):-m(M,_,_).
%qr('bitseq',m(M),''):-m(M,_,_).
%qr('rsem',m(M),''):-m(M,_,_).
%qr('isoem',m(M),''):-m(M,_,_).
%qr('sailfish',m(M),''):-m(M,_,_).

qr(none,m(M),'',_):-m(M,_,_,_S).

qn(cufflinks1,qr(cufflinks1),_,stranded).
qn(cufflinks2,qr(cufflinks2),_,stranded).
qn(cufflinks1_nd,qr(cufflinks1_nd),_,stranded).
qn(cufflinks2_nd,qr(cufflinks2_nd),_,stranded).
qn(nurd,qr(nurd),_,no).
qn(stringtie,qr(stringtie),_,no).
qn(stringtie_nd,qr(stringtie_nd),_,no).
qn(flux_cap,qr(flux_cap),_,no).
qn(deseq,qr(QR),_,_):-member(QR,[flux_cap,basic,htseq1,htseq2]).
qn(deseq2,qr(QR),_,_):-member(QR,[flux_cap,basic,htseq1,htseq2]).
qn(none,qr(_),_,_).


de(deseq,(qr(QR),qn(QN)),_):-all_quant(ALL_QN),member(QR,ALL_QN),all_quant_norm(ALL_QNorm),member(QN,ALL_QNorm).
de(deseq2,(qr(QR),qn(QN)),_):-all_quant(ALL_QN),member(QR,ALL_QN),all_quant_norm(ALL_QNorm),member(QN,ALL_QNorm).
de(edger,(qr(QR),qn(QN)),_):-all_quant(ALL_QN),member(QR,ALL_QN),all_quant_norm(ALL_QNorm),member(QN,ALL_QNorm).
de(voom,(qr(QR),qn(QN)),_):-all_quant(ALL_QN),member(QR,ALL_QN),all_quant_norm(ALL_QNorm),member(QN,ALL_QNorm).
%de(dexseq,(qr(QR),qn(QN)),_):-member(QR,[htseq1,htseq2,basic,flux_cap]),member(QN,[deseq,flux_cap,none]).
%de(bayseq,(qr(QR),qn(QN)),_):-member(QR,[htseq1,htseq2,basic,flux_cap]),member(QN,[deseq,flux_cap,none]).
de(cuffdiff1,(qr(QR),qn(QR)),_):-member(QR,[cufflinks1,cufflinks2]).
de(cuffdiff2,(qr(QR),qn(QR)),_):-member(QR,[cufflinks1,cufflinks2]).
de(cuffdiff1_nd,(qr(QR),qn(QR)),_):-member(QR,[cufflinks1_nd,cufflinks2_nd]).
de(cuffdiff2_nd,(qr(QR),qn(QR)),_):-member(QR,[cufflinks1_nd,cufflinks2_nd]).
de(none,(qr(_),qn(_)),_).
%de(edger,(qr(QR),_),_):-member(QR,[htseq1,htseq2,basic,flux_cap]).



gse(none,_,_).
gse(piano,de(DE),_):- all_de(ALL_DE),member(DE,ALL_DE).
% (ground(DE)->not member(DE,[none]);true).
