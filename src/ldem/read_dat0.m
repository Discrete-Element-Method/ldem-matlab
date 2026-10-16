
function ini= read_dat0()
% READ_DAT0  Lê os dados de entrada dos arquivos DATNAME(I).
global  INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED C
global OU2 OU3 OU4 OU5 OU6 OU7 OU8 OU9

% !  DATA:  27/04/2024
% !  AUTOR: IGNACIO ITURRIOZ
% !
% !  Esta subrotina lê os dados de entrada dos arquivos DATNAME(I).
% !
% !--------------------------------------------------------------------------
% !  VARIÁVEIS LIDAS DO ARQUIVO DE ENTRADA DATNAME(I)
% !--------------------------------------------------------------------------
% !
% !  TEST = (INTEGER) NÚMERO DO TESTE A SER REALIZADO
% !   SEED= (INT) SEMENTE DE GERACAO DE NUMEROS ALEATORIOS   
% !
% !  LCo = (REAL) COMPRIMENTO DA ARESTA DO MÓDULO CÚBICO SEM DEFORMAR
% !
% !  M, N, L = (INTEGER) DIMENSÕES MODULARES DAS ARESTAS DO PRISMA.
% !            REPRESENTAM O NÚMERO DE NÓS PRESENTES NAS ARESTAS DO PRISMA
% !            PARALELAS AOS EIXOS CARTESIANOS X,Y,Z, RESPECTIVAMENTE.
% !
% !  DF1, DF2 = (REAL) COEFICIENTES DE AMORTECIMENTO PROPORCIONAL À MASSA
% !             INICIAL E FINAL  M(X)''+DF(X)'=FX
% !
% !  TDAF = (REAL) TEMPO DE TROCA DO AMORTECIMENTO DF1 PARA DF2
% !
% !  CON = (REAL) AMORTECIMENTO CONSIDERADO DENTRO DA EQUAÇÃO CONSTITUTIVA
% !        (EST=1)
% !
% !  DT = (REAL) INTERVALO DE INTEGRAÇÃO. DT<=0.6*LCO/C0, SENDO C0=(E/RO)**.5
% !
% !  TTOT = (REAL) TEMPO TOTAL DE INTEGRAÇÃO
% !
% !  INCO = (INTEGER) NÚMERO DE PONTOS DE CONTROLE A CONSIDERAR (INCO<=INCON)
% !
% !  NCON(I) = (INTEGER) I-ÉSIMO PONTO DE CONTROLE A CONSIDERAR (I=1,INCO)
% !
% !  OU2, OU3, OU4, OU5, OU6, OU7, OU8, OU9 = (INTEGER) CONTROLE DA EDIÇÃO DE
% !                                            ARQUIVOS DE SAÍDA
% !       OU2,OU3,OU4,OU5,OU6,OU7,OU8,OU9 = 0, ARQUIVO NÃO SE IMPRIME
% !       OU2 = n, ARQUIVO SE IMPRIME
% !       OU3 = n, SE IMPRIME 1 ARQUIVO NO TEMPO ZERO E ARQUIVOS A CADA n
% !                PASSOS DE INTEGRAÇÃO
% !       OU4 = n, SE IMPRIMEM ARQUIVOS A CADA n PASSOS DE INTEGRAÇÃO
% !       OU5,OU6,OU7,OU8,OU9 = n, SE IMPRIMEM VALORES A CADA n PASSOS DE
% !                                INTEGRAÇÃO
% !
% !  PSN = (REAL) COEFICIENTE DE POISSON
% !
% !  ROH = (REAL) MASSA ESPECÍFICA
% !
% !  YNG = (REAL) MÓDULO DE YOUNG
% !
% !  GFR = (REAL) ENERGIA ESPECÍFICA DE FRATURA
% !
% !  DEQ= (REAL) Equivalence Distance
% !
% !--------------------------------------------------------------------------
% !  FORMATO DO ARQUIVO DE ENTRADA DATNAME(I)
% !--------------------------------------------------------------------------
% !  TEST,LCO,M,N,L,
% !  DF1,DF2,TDAF,CON,
% !  DT,TTOT,
% !  INCO,NCON(1),NCON(2),...,NCON(INCO),
% !  OU2,OU3,OU4,OU5,OU6,OU7,OU8,OU9,
% !  PSN,ROH,YNG,GFR,DEQ
% ! 
%C = textscan(fileID,formatSpec)
[C]=textread('DATA0.DAT','%s %*[^\n]') 
% we enter de data in char format
TEST=str2double(C(1))
SEED=str2double(C(2))% SEED to create a pertubed mesh  '
LCO=str2double(C(3))  %cubic module  length
M= str2double(C(4))
N= str2double(C(5))
L= str2double(C(6)) 
DF1 =str2double(C(7))
DF2 =str2double(C(8))
 TDAF=str2double(C(9))
 CON =str2double(C(10))
 DT =str2double(C(11))
 TTOT =str2double(C(12))
INCO= str2double(C(13)) 
for i=1:INCO 
NCON(i)= str2double(C(13+i))
end
OU2 =str2double(C(14+INCO));% OU2
OU3 =str2double(C(15+INCO));% OU3
OU4 =str2double(C(16+INCO));% OU4
OU5 =str2double(C(17+INCO));% OU5
OU6 =str2double(C(18+INCO));% OU6
OU7 =str2double(C(19+INCO));% OU7
OU8 =str2double(C(20+INCO));% OU8
OU9 =str2double(C(21+INCO));% OU9
PSN =str2double(C(22+INCO))
ROH =str2double(C(23+INCO))
YNG =str2double(C(24+INCO))
GFR=str2double(C(25+INCO))
DEQ =str2double(C(26+INCO))

 %  fid = fopen('dados.txt', 'r');
% A = fscanf(fid, '%f');  % Lê todos os números
% fclose(fid);
%       READ (10,*)TEST,TEXTO,SEED,TEXTO,LCO,TEXTO,M,TEXTO,N,TEXTO,L,TEXTO
%       READ (10,*) DF1,TEXTO,DF2,TEXTO,TDAF,TEXTO,CON,TEXTO
%       READ (10,*) DT,TEXTO,TTOT,TEXTO,INCO,TEXTO
% !
%       DO 10 I=1,INCO
%         READ (10,*) NCON(I),TEXTO
%    10 CONTINUE
% !
%       READ (10,*) OU2,TEXTO,OU3,TEXTO,OU4,TEXTO,OU5,TEXTO
%       READ (10,*) OU6,TEXTO,OU7,TEXTO,OU8,TEXTO,OU9,TEXTO
%       READ (10,*) PSN,TEXTO,ROH,TEXTO,YNG,TEXTO
%       READ (10,*) GFR,TEXTO,DEQ,TEXTO
%       RETURN
%       END
% !
 ini=1;
 end
