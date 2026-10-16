% boris
a= 1
b = 2
c= 3


clear all
clc
global INT INB U V W U0 V0 W0 BDX BDY BDZ VLX VLY VLZ 
global ACX ACY ACZ FRX FRY FRZ FX FY FZ MAS MSS CN ENR
global EDG E1 E2 LI DEQB F YNGB GFRB LCRB EPRB EP SS EM
global EN KR KR1 DSS DM FS CAF DT GFR DEQ LCR TEST EST 
global DF DF1 DF2 DMP1 DMP2 TDAF CON M N L M1 N1 L1 MNL
global NNO NNS NNT NBA NBS NBT INCO NCON STEP NSTEP NDAMF
global RUN NRUN LCO TIME TTOT PSN ROH YNG EPR EPMAX EPMIN 
global MEAN  COEV ENEX ENCN ENEL ENGD ENDP ENIN DEN DERIV 
global XB YB ZB UBAR VBAR WBAR REACAOX REACAOY REACAOZ 
global STRAIN STRESS SEED 
global OU2 OU3 OU4 OU5 OU6 OU7 OU8 OU9

%
ini=ini_DEM3()  %an initialization of the main variables was done
%
DATNAME=' ';
CONNAME=' ';
ANSNAME=' ';
RESNAME=' ';
DISNAME=' ';
POSNAME=' ';
ENENAME=' ';
%ARMANS(1000)='              ';
cont1=0;
cont2=0;
cont3=0;
cont4=0;
cont5=0;
cont6=0;
%counter of the linked the file writing
PR3=1; %Ansys File
PR67=1; %DIS and POS  files
PR8=1; %ENE file
PR9=1; % SIM01 file inside CALRES
%
      % CHARACTER*14 DATNAME,CONNAME
      % CHARACTER*14 ANSNAME,RESNAME,DISNAME
      % CHARACTER*14 POSNAME,ENENAME
      % CHARACTER*14 ARMANS(10000000)
      % integer cont1,cont2,cont3,cont4,cont5,cont6,B,bb
%
%
% !
%       OPEN (UNIT=10,ACCESS='SEQUENTIAL',FILE='DATA0.DAT',&
%      &     STATUS='OLD')
%   
% !
% !     READAT -----> L os dados que esto no arquivo DATA0.DAT
      % CALL READAT0
      ini=read_dat0() % read the input data saved in DATA0.DAT
      'ini=read_dat0()'
      %
      % !
%     Close (10)
% !
% !--------------------------------------------------------------------------
% !  PREPARAO DAS VARIVEIS E CHAMAMENTO DAS SUBROTINAS PRELIMINARES
% !--------------------------------------------------------------------------
% !
% 
% !     PREPVAR ----> setting of initial parameters
% CALL PREPVAR 
 ini=prepvar()  %setting of initial parameters    
'ini=prepvar()'
 
 % !
% !     COORD ------> Gera coordenadas de um prisma
%       CALL COORD
ini=COORD() % Build the nodes coordinate of prism  with MxNxL modules 
'ini=COORD()'

% !
% 
% 
% !     IMPERF -----> Impe uma aleatoriedade (imperfeio) s coordenadas
%       CALL IMPERF
ini=IMPERF()% !
'ini=IMPERF()'
% !     BOUND ------> Determina as condies de contorno da estrutura
%       CALL BOUND
ini=BOUND()% !
'ini=BOUND()'
% !
% !     NODMASS ----> Atribui um valor de massa a cada n da estrutura
%       CALL NODMASS
ini=NODMASS()% !
'ini=NODMASS()'
% !
% !     CONECTI ----> Gera conectividades das barras
%       CALL CONECTI
ini=CONECTI()% !
'ini=CONECTI()'
% !
% !     CALAUX -----> Clculos auxiliares e determinao compr. cada barra
%       CALL CALAUX
ini=CALAUX()% !

'ini=CALAUX()'
%
% 
%      OPEN (UNIT=70,ACCESS='SEQUENTIAL',FILE='BARI.txt',&
%     &        STATUS='UNKNOWN')
% 
%     DO I=1, NBT
%       WRITE(70,'(I7,3X,3(E25.12,3X))') I,XB(I),YB(I),ZB(I)
% 
%     ENDDO
% 
%     CLOSE(70)
% Open the file for writing ('w' creates/overwrites, equivalent to STATUS='UNKNOWN')
fid = fopen('BARI.txt', 'w');

% Loop equivalent to DO I=1, NBT
for I = 1:NBT
    % fprintf replaces WRITE with formatted output
    % Format spec: %7d (I7), 3 spaces (3X), 3 floating-point values in scientific notation (E25.12)
    fprintf(fid, '%7d   %25.12E   %25.12E   %25.12E\n', I, XB(I), YB(I), ZB(I));
end

% Close the file
fclose(fid);
'The file BARI.txt was made'



% !   
% !     NAYFES0 ---->BAR STIFNESS DETERMINATION
%       CALL NAYFES0
ini=NAYFES0()
'ini=NAYFES0()'
% !     RMEC ------->BAR STIFNESS DETERMINATION 
%       CALL RMEC
ini=RMEC()
'ini=RMEC()'


% --- Introduce random field into EP(B) ----------------------------------
fid = fopen('arquivo_3lc_rnao_cv05', 'r');
if fid == -1
    error('Console1: cannot open arquivo_3lc_rnao_cv05');
%    !arquivo_lc3l_rnao_cv100.txt
%    !arquivo_3lc_rnao_cv05.txt      
end
for I = 1:NBT
    Phitemp = fscanf(fid, '%f', 1);
    EP(I) = Phitemp * EP(I);
    EM(I) = EP(I);            % very important!!!
end
fprintf('%g\n', EP(1));
fclose(fid);

ini=CALCOEV() % computation of Mean value and variation 
% coeficient of EP 
'ini=CALCOEV()' 
%  ini= NEIBOUR()   !WE NEED THIS SBROUTINE TO COMPUTE BARS 
% THAT ARRIVING IN THE NODS i AND J OF THE b BAR
% 'ini=CALCOEV()'  ( We need to implement)
% 
% !--------------------------------------------------------------------------
% !  ABRINDO OS ARQUIVOS DE SADA
% !--------------------------------------------------------------------------
fid_CON = -1; fid_AN1 = -1; fid_RES = -1;
fid_DIS = -1; fid_POS = -1; fid_ENE = -1;
fid_Lei = -1; fid_EnB = -1;

if OU2 > 0, fid_CON = fopen('LET.CON', 'w'); end
if OU3 > 0, fid_AN1 = fopen('LET.AN1', 'r'); end
if OU5 > 0, fid_RES = fopen('LET.RES', 'w'); end
if OU6 > 0, fid_DIS = fopen('LET.DIS', 'w'); end
if OU7 > 0, fid_POS = fopen('LET.POS', 'w'); end
if OU8 > 0, fid_ENE = fopen('LET.ENE', 'w'); end
if OU9 > 0, fid_Lei = fopen('Lei_Barra.TXT',   'w'); end
if OU9 > 0, fid_EnB = fopen('Energia_Barra.TXT','w'); end
% !
%       IF (OU2.GT.0)&
%      &  OPEN (UNIT=12,ACCESS='SEQUENTIAL',FILE='LET.CON',&
%      &        STATUS='UNKNOWN')
% !
%       IF (OU3.GT.0)&
%      &  OPEN (UNIT=13,ACCESS='SEQUENTIAL',FILE='LET.AN1',&
%      &        STATUS='UNKNOWN')
% 
%       IF (OU5.GT.0)&
%      &  OPEN (UNIT=15,ACCESS='SEQUENTIAL',FILE='LET.RES',&
%      &        STATUS='UNKNOWN')
% !
%       IF (OU6.GT.0)&
%      &  OPEN (UNIT=16,ACCESS='SEQUENTIAL',FILE='LET.DIS',&
%      &        STATUS='UNKNOWN')
% !
%       IF (OU7.GT.0)&
%      &  OPEN (UNIT=17,ACCESS='SEQUENTIAL',FILE='LET.POS',&
%      &        STATUS='UNKNOWN')
% !
%       IF (OU8.GT.0)&
%      &  OPEN (UNIT=18,ACCESS='SEQUENTIAL',FILE='LET.ENE',&
%      &        STATUS='UNKNOWN')
% 
%  !                                     
%       IF (OU9.GT.0)&
%      &  OPEN (UNIT=19,ACCESS='SEQUENTIAL',FILE='Lei_Barra.TXT',&
%      &        STATUS='UNKNOWN')
% 
%    !                           
%       IF (OU9.GT.0)&
%      &  OPEN (UNIT=20,ACCESS='SEQUENTIAL',FILE='Energia_Barra.TXT',&
%      &        STATUS='UNKNOWN')
%    !--------------------------------------------------------------------------
%       IF (OU2.GT.0) THEN
% !     WRICON -----> Gravao de informao de entrada no arquivo CONNAME
%       CALL WRICON
%    ! We close(2) in the end of the Main program 
%       END IF
% !--------------------------------------------------------------------------
% !  LEITURA NOMES DE ARQUIVOS DO ANSYS
% !--------------------------------------------------------------------------
% 
%       !
%       IF (OU3.GT.0) THEN
%         DO 30 III=1,(NSTEP/OU3)+1
%           READ (13,*) ARMANS(III)
%    30   CONTINUE
%         CLOSE (13)
% !
% 
% !--------------------------------------------------------------------------
% !  GRAVAO DO PRIMEIRO ARQUIVO DO ANSYS
% !--------------------------------------------------------------------------
%         I3=1
%         OPEN (UNIT=13,ACCESS='SEQUENTIAL',FILE=ARMANS(I3),&
%      &        STATUS='UNKNOWN')
%         WRITE (13,*) '!ARQUIVO NO TEMPO =',TIME
%         CALL ANSYS (13,CONT1,CONT2,CONT3,CONT4,CONT5,CONT6)
%         CLOSE (13)
%       END IF


% -------------------------------------------------------------------------
if OU2 > 0
    % WRICON -----> writes input info to CONNAME
 ini=WRICON(fid_CON);   % stream passed in (or use global fid)
'ini=WRICON'
end

% -------------------------------------------------------------------------
% READ FILENAMES OF ANSYS FILES
% -------------------------------------------------------------------------
I3 = 1;
if OU3 > 0
ARMANS = cell(floor(NSTEP/OU3) + 1, 1);
for III = 1:floor(NSTEP/OU3) + 1
ARMANS{III} = strtrim(fgetl(fid_AN1));   % l uma linha e remove espaos
    end
       fclose(fid_AN1);



    % --- Write first ANSYS file -----------------------------------------
    fid_AN1 = fopen(ARMANS{I3}, 'w');
    fprintf(fid_AN1, '!ARQUIVO NO TEMPO = %g\n', TIME);



        ini= ANSYS(fid_AN1, cont1, cont2, cont3, cont4, cont5, cont6);
     'ini=ANSYS'
   fclose(fid_AN1);
end

% 
% !--------------------------------------------------------------------------
% !  CONCLUIU-SE A MONTAGEM DO MODELO. INICIA-SE A INTEGRAO PASSO A PASSO
% !--------------------------------------------------------------------------
% !  LOOP PRINCIPAL DE INTEGRAO
% !--------------------------------------------------------------------------
% 
% 
% 
%       WRITE (*,*)
%       WRITE (*,*) '  *** PERFORMING THE INTEGRATION STEP BY STEP **  '
%       WRITE (*,*)
% !
%       STEPP=1
% !
%       DO 60 STEP = STEPP,NSTEP
% !
% !--------------------------------------------------------------------------
% !  Escreve uma informao de controle na tela em cada passo de integrao
% !--------------------------------------------------------------------------
%       WRITE (*,40) STEP
% 40    FORMAT ('   STEP     ======================>  ',I7,' / ',I2)
% 
% !
% !--------------------------------------------------------------------------
% !  Controle de mudana de amortecimento
% !--------------------------------------------------------------------------
%       IF (STEP.EQ.NDAMF) THEN
%         DF1=DF2
%         DMP1=1.0D00-DF2*DT/2.0D00
%         DMP2=1.0D00+DF2*DT/2.0D00
%       END IF
% !
% !--------------------------------------------------------------------------
% !  Incremento do tempo
% !--------------------------------------------------------------------------
%       TIME=TIME+DT
%       WRITE (*,50) TIME
% 50    FORMAT ('   TIME     ======================>  ',F12.8)
%-------------------------------------------------------------------------
% !  Avaliao das foras e determinao da nova configurao
% !--------------------------------------------------------------------------
% !     CALOAD -----> Clculo das cargas sobre os ns
%       CALL CALOAD
%       write(*,*) 'caload' 
% !
% !  Especifica-se a carga em cada tempo e calcula-se a energia externa
% !  fornecida ao sistema. Em funo do exemplo tem-se que modificar esta
% !  subrotina.
% !
% !--------------------------------------------------------------------------
% !     CABAR ------> compute de nodal forces in the structure, in CABAR we have a loop over all the bars and
%       ! we call the constit subroutine to compute the forces in each bars
%       CALL CABAR
%  write(*,*) 'cabar' 
% !
% !--------------------------------------------------------------------------
% !     IGN012 -----> Clculo das coordenadas no tempo TIME aplicando
% !                   diferenas finitas centrais na equao do movimento
%       CALL IGN012
% !  Nesta subrotina realiza-se a integrao via mtodo das diferenas
% !  finitas centrais. Tem-se um loop sobre os ns. Entra-se com as foras
% !  calculadas em CABAR e com a configurao do sistema nos dois tempos
% !  anteriores e determina-se a configurao no tempo novo.
% !
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% MODEL ASSEMBLY COMPLETE. START STEP-BY-STEP INTEGRATION
% -------------------------------------------------------------------------
fprintf('\n  *** PERFORMING THE INTEGRATION STEP BY STEP **  \n\n');

STEPP = 1;

for STEP = STEPP:NSTEP

    fprintf('   STEP     ======================>  %7d / %2d\n', STEP, 0);

    % ---------------------------------------------------------------------
    % Damping change control
    % ---------------------------------------------------------------------
    if STEP == NDAMF
        DF1  = DF2;
        DMP1 = 1.0 - DF2 * DT / 2.0;
        DMP2 = 1.0 + DF2 * DT / 2.0;
    end

    % ---------------------------------------------------------------------
    % Time increment
    % ---------------------------------------------------------------------
    TIME = TIME + DT;
    fprintf('   TIME     ======================>  %12.8f\n', TIME);
    fprintf('\n');
    % ---------------------------------------------------------------------
    % Evaluate forces and determine new configuration
    % ---------------------------------------------------------------------
    ini=CALOAD();
   'ini=CALOAD()'
    
   ini=CABAR(fid_Lei);
   'ini=CABAR()'

   ini=IGN012();     % central finite differences integration
   'ini=IGN012()'
% !--------------------------------------------------------------------------
% !  Gerao dos arquivos de sada
% !--------------------------------------------------------------------------
% !  SADA - VISUALIZAO NO ANSYS
% !--------------------------------------------------------------------------
%      IF (PR3.EQ.OU3) THEN
%         I3=I3+1
%         PR3=1
%         OPEN (UNIT=11,ACCESS='SEQUENTIAL',FILE=ARMANS(I3), &
%       &                STATUS='UNKNOWN')
%         WRITE (11,*) '!ARQUIVO NO TEMPO =',TIME
%         CALL ANSYS (11,CONT1,CONT2,CONT3,CONT4,CONT5,CONT6)
%         CLOSE (11)
%       ELSE
%         PR3=PR3+1
%       END IF
% !
% !--------------------------------------------------------------------------
% !  SADA - REAES NODAIS
% !--------------------------------------------------------------------------
%       ! write(*,*) 'antes de calres'
% !      CALRES -----> Clculo de resultados que sero gravados em RESNAME
%        CALL CALRES
%       !  write(*,*) 'calres' 
%       !
% !--------------------------------------------------------------------------
% !  SADA - CONTROLE DE DESLOCAMENTOS, VELOCIDADES E ACELERAES
% !--------------------------------------------------------------------------
% !
%       IF (PR67.EQ.OU6) THEN
%         CALL WRIDIPO
% !!  Esta subrotina grava os arquivos *.dis e *.pos que tem os valores dos
% !  deslocamentos, velocidades e aceleraes nos ns de controle.
% !
%         PR67=1
%       ELSE
%         PR67=PR67+1
%       END IF
% !--------------------------------------------------------------------------
% !  SADA - AVALIAO DA ENERGIA
% !--------------------------------------------------------------------------
% !
% !     ENERG2 -----> Clculo das energias que sero gravadas em ENENAME
%       CALL ENERG2
% !  Esta subrotina calcula em cada tempo as energias que esto se
% !  transformando no processo.
% !
%       IF (PR8.EQ.OU8) THEN
%         CALL WRIENE
% !  Esta subrotina grava o arquivo *.ene que tem os valores das energias.
% !
%         PR8=1
%       ELSE
%         PR8=PR8+1
%       END IF
% 
% !
% !--------------------------------------------------------------------------
%    60 CONTINUE
% !--------------------------------------------------------------------------
% !
%       IF (RUN.EQ.NRUN) GO TO 70
% !
%       IF (OU5.GT.0) CLOSE (5)
%       IF (OU6.GT.0) CLOSE (6)
%       IF (OU7.GT.0) CLOSE (7)
%       IF (OU8.GT.0) CLOSE (8)
% !    
% !
%      70 CONTINUE
% !
% 
%       WRITE (*,*)
%       WRITE (*,*) '  ****************** THE END *******************  '
%       WRITE (*,*)
% 
%      close(22)
%      close(2)
%     end program Console1
 % ---------------------------------------------------------------------
    %  Generate output files
    % ---------------------------------------------------------------------

    % Output - ANSYS visualisation
    if PR3 == OU3
        I3 = I3 + 1;
        PR3 = 1;
        fid11 = fopen(ARMANS(I3), 'w');
        fprintf(fid11, '!ARQUIVO NO TEMPO = %g\n', TIME);
        [CONT1, CONT2, CONT3, CONT4, CONT5, CONT6] = ...
         ini==ANSYS(fid11, CONT1, CONT2, CONT3, CONT4, CONT5, CONT6);
        'ini=ANSYS()'
        fclose(fid11);
    else
        PR3 = PR3 + 1;
    end

  
    % ---------------------------------------------------------------------
    %  Output - control of displacements, velocities and accelerations
    % ---------------------------------------------------------------------
    if PR67 == OU6
    % Output - nodal reactions
    % CALRES -----> Compute results to be written to RESNAME
       ini=CALRES();
       'ini=CALRES()'

        ini=WRIDIPO(fid_DIS, fid_POS);
        'ini=WRIDIPO'
        PR67 = 1;
    else
        PR67 = PR67 + 1;
    end

    % ---------------------------------------------------------------------
    %  Output - energy evaluation
    % ---------------------------------------------------------------------
    % ENERG2 -----> Compute energies to be written to ENENAME
    ini=ENERG2(fid_EnB);
     'ini=ENERG2()'
    if PR8 == OU8
        ini=WRIENE(fid_ENE);
        'ini=WRIENE'

        PR8 = 1;
    else
        PR8 = PR8 + 1;
    end

end
% -------------------------------------------------------------------------

if RUN == NRUN
    % GO TO 70
else
    if OU5 > 0 && fid15 >= 0, fclose(fid15); end
    if OU6 > 0 && fid_DIS>= 0, fclose(fid_DIS); end
    if OU7 > 0 && fid_POS >= 0, fclose(fid_POS); end
    if OU8 > 0 && fid_ENE >= 0, fclose(fid_ENE); end
end

% 70 CONTINUE

fprintf('\n');
fprintf('  ****************** THE END *******************  \n');
fprintf('\n');

% Close remaining open files
if fid19 >= 0, fclose(fid19); end
if fid20 >= 0, fclose(fid20); end
if fid12 >= 0, fclose(fid12); end

% End of program Console1



