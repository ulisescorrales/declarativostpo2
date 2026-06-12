:- use_module(library(random)).
:- use_module(library(clpfd)).
:- consult('./ronda.pl').

%El juego de la escoba modelado posee la siguientes reglas:
%Primero se mezclan las cartas del mazo y se reparten 4 en la mesa y 3 a cada jugador.
%Cada jugador elige una carta, elige tirarla o intentar sumar 15 puntos con el set de cartas dispoible en la mesa
%Si al sumar 15 puntos deja la mesa sin cartas para elegir, hace "escoba" y suma un punto.
%Luego de cada ronda se verifica si alcanza a repartirse cartas a cada jugador, de lo contrario se termina el juego.
%Al final se suma el puntaje obtenido según el mazo de cartas que se apropió cada jugador al hacer sumar 15 puntos en cada ronda.
%Gana el que obtuvo mayor puntaje
%Los estados del sistema se programan en escoba.pl, donde se invocan las rondas mientras se pueda seguir jugando. Los estados de una ronda se programaron en ronda.pl
escoba(Jugadores) :-
	%Jugadores es una lista de jugador(Nombre,WebSocket)
	format("Jugadores: ~w~n",[Jugadores]),
	phrase(escoba(Jugadores),[_],[_]).
escoba(Jugadores)--> 
	reset,
	crear_jugadores(Jugadores), % Llegan por websockets
	%dejar 4 cartas en la mesa
	dejar_carta_en_mesa,
	dejar_carta_en_mesa,
	dejar_carta_en_mesa,
	dejar_carta_en_mesa,
	play_rounds,
	calcular_puntos
	.
reset -->
	%Establecer el estado inicial del juego (Set de cartas disponibles y nula cantidad de cartas en la mesa)
    state(_, [stock(CardsShuffled),cartasMesa([])]),
    {
        setof(Card, card(Card), Cards),
        random_permutation(Cards, CardsShuffled),
        format("Cartas creadas ~n")
    }.

crear_jugadores(Jugadores) -->
	%Misma forma que en brisca.pl, se agrega el tercer atributo (Traidas, que son las cartas que junta el jugador cuando suma 15 con alguna de su Baraja) y el cuarto (Puntaje)
    state(S0, S),
    {
		same_length(Players, Jugadores),
		%Aquí se define la estructura de player(Nombre,Baraja,Traidas,Puntaje), siendo Baraja las cartas que tiene en mano actualmente
		%El Puntaje empieza en cero, se suma uno cuando hace una escoba mientras juega y al final del juego cuando se verifica la cantidad de cartas, oros, sietes y 7-oro que tienen los jugadores
		% format("Jugadores entrada: ~w~n",[Jugadores]),
		maplist([player(Nombre,WS),X]>>(X=player(Nombre, [], [],0,WS)), Jugadores, Players),
		S = [players(Players)|S0]
		% format("Jugadores creados: ~w~n",[Players])
    }
	.

dejar_carta_en_mesa-->
	%Del estado se modifica la propiedad cartasMesa(X) para agregarle una carta del stock(Cima|Resto)
	state(S0,S),
	{
		select(stock(CartasTotales),S0,S1),
		CartasTotales=[Cima|Resto],
		select(cartasMesa(CartasMesa),S1,S2),
		S=[stock(Resto),cartasMesa([Cima|CartasMesa])|S2]
		% ,format("Cartas en la mesa: ~w~n",[[Cima|CartasMesa]])
	}.
play_rounds -->
	%Verificar que se pueda seguir jugando, los jugadores no tienen cartas en su Baraja
	state(S0),
	{
		member(stock(Stock),S0),
		member(players(Players),S0),
		Players=[Player|_],
		Player=player(_,Baraja,_,_,_),
		length(Baraja,0),%Solo repartir cartas si no hay mas baraja de donde elegir
		length(Stock,N1),
		length(Players,N2),
		N1>=N2
		% format("play_rounds - Players:  ~w~n",[Players])
	},
	repartir_tres_cartas%Reparte a jugadores, luego vuelve a invocar play_rounds
	.
play_rounds -->
	%Verificar que se pueda seguir jugando, sin repartir cartas (los jugadores todavía tienen cartas en su Baraja)
	state(S0),
	{
		member(players(Players),S0),
		Players=[Player|_],
		Player=player(_,Baraja,_,_,_),
		length(Baraja,L),%Solo repartir cartas si no hay mas baraja
		L>0,
		member(cartasMesa(CartasMesa),S0)
	},
	play_round(Players,CartasMesa)%Como todavía tienen cartas, jugar otra ronda sin repartir
	.
play_rounds -->
	%No hay mas baraja para elegir y las cartas del stock no alcanzan para repartir 
	%%a los jugadores, finalizar
	state(S0),
	{
		member(players(Players),S0),
		Players=[Player|_],
		Player=player(_,Baraja,_,_,_),
		length(Baraja,0),
		member(stock(Stock),S0),
		length(Stock,N1),
		length(Players,N2),
		N1<N2,
		format("No hay más cartas para repartir, finaliza el juego ~n")
	}
	.
informarCartasMesaYJugador(PlayerNow) -->
	state(S),
	{
		member(players(Players),S),
		member(cartasMesa(CartasMesa),S),
		%Informar cartas en la mesa
		format(string(Mensaje),"cartas disponibles: ~w",[CartasMesa]),
		forall(member(player(_,_,_,_,WS), Players),ws_send(WS, text(Mensaje))),
		%Informar jugador actual
		PlayerNow=player(Nombre,Baraja,Traidas,Puntaje,WS),
		format(string(Mensaje2),"turno de: ~w",[Nombre]),
		forall(member(player(_,_,_,_,WS2), Players),ws_send(WS2, text(Mensaje2)))
	}
.
play_round([Player|Resto],CartasMesa)-->
	%Comienza la ronda de juego, cada jugador elige una carta de su baraja y la tira a la mesa o intenta sumar 15 puntos y trae varias cartas a su mazo
	%Se hace el llamado a jugar_jugador por cada Player en la lista de Players y se actualiza el nuevo estado
	informarCartasMesaYJugador(Player),
	state(S0,S),
	{
		Player=player(Nombre,Baraja,Traidas,Puntaje,WS),
		% format("Turno para ~w~n",[Nombre]),
		phrase(jugar_jugador(CartasMesa,[Nombre,Baraja,Traidas,Puntaje,WS],CartasMesa2,Player2),[_],_), %jugar_jugador programado en ronda.pl
		Player2=[Nombre2,Baraja2,Traidas2,Puntos2,WS],
		select(players(PS),S0,S1),
		select(cartasMesa(_),S1,S2),
		select(player(Nombre,_,_,_,_),PS,PS1),
		append(PS1,[player(Nombre2,Baraja2,Traidas2,Puntos2,WS)],PS2),
		S=[players(PS2),cartasMesa(CartasMesa2)|S2]
	},
	play_round(Resto,CartasMesa2)
	.
play_round([],_)-->[]
	%Cuando ya se terminó la ronda (jugaron todos)
	,
	play_rounds
.
repartir_tres_cartas -->
	%Reparte tres cartas del mazo a cada jugador
	
	entregar_carta_a_cada_jugador,
	entregar_carta_a_cada_jugador,
	entregar_carta_a_cada_jugador,
	state(S),
	{
		% format("S repartiendo cartas: ~w~n",[S]),
		member(players(Players),S),
		member(cartasMesa(CardsTable),S),
		format("Repartidas tres cartas a cada jugador ~n"),
		format("Jugadores: ~w~n",[Players])
	},
	play_round(Players,CardsTable). %Va recorriendo la lista de jugadores
entregar_carta_a_cada_jugador -->
	%Reparte una sola carta del mazo a cada jugador (invocado por repartir_tres_cartas)
    state(S0, S),
    {
	select(players(Players), S0, S1),
	select(stock(Cards), S1, S2),
	% format("Empezar a repartir a cada jugador ~n"),
	% format("Players entrega: ~w~n",[Players]),
	repartir_cartas(Players, Players1, Cards, Cards1),
	S = [players(Players1), stock(Cards1)|S2] %Players1 poseen cartas, Cards1 es el sobrante
	% ,format("~w~n",[S])
    }.

repartir_cartas([], [], Cs, Cs). %Se repartieron a todos los jugadores
repartir_cartas(Ps, Ps, [], []).%Ya no quedan cartas para repartir
repartir_cartas([P|Ps], [P1|Ps1], [C|Cs], Cs1) :-
    P = player(Nombre, A0,Traidas,Puntos,WS), 
    P1 = player(Nombre, [C|A0],Traidas,Puntos,WS), %Agregar una carta al nuevo estado de player
    repartir_cartas(Ps, Ps1, Cs, Cs1). %Seguir repartiendo

calcular_puntos -->
	state(S0,S),
	{
		select(players(Players),S0,S1),
		% format("empezar calcular puntos ~n"),
		sumar_puntos(Players,Players2),
		S=[players(Players2)|S1]
	},
	calcular_ganador
	.
calcular_ganador -->
	%Revisa de todos los jugadores quien o quienes (empate) tienen el puntaje máximo.
	state(S0),
	{
		member(players(Players),S0),
		ganadores(Players,R),
		format("Ganadores: ~w~n",[R]),
		format(string(Mensaje),"Ganadores: ~w~n",[R]),
		format("~w~n",[Players]),
		%Anunciar ganadores y cerrar las conexiones
		forall(member(player(_,_,_,_,WS), Players),ws_send(WS, text(Mensaje))),
		forall(member(player(_,_,_,_,WS), Players),ws_close(WS,1000,"Finaliza el juego")),
		%Avisar al server que deje de ejecutar esperar_fin_juego y terminar
    	main_thread(MainThread),
		thread_send_message(MainThread, fin_juego),
		thread_send_message(thread_ws, fin_juego),
		halt
}.

ganadores(Players,R):-
	%Recibe la lista de jugadores Players
	%R es la lista resultante
	puntos_max(Players,0,_,R).


puntos_max([Player|T],Temp,Max,RFinal):-
	%Busca el máximo puntaje entre los Players
	Player=player(_,_,_,Puntos,_),
	Puntos < Temp ,
	puntos_max(T,Temp,Max,RFinal).%Sigue llamando sin cambios
puntos_max([Player|T],Temp,Max,RFinal2):-
	%Caso: El jugador tiene mayor puntaje
	Player=player(Nombre,_,_,Puntos,_),
	Puntos>=Temp,
	Temp2 is Puntos,
	puntos_max(T,Temp2,Max,RFinal),
	%Verifica a la vuelta de la secuencia de llamadas si Temp2 es máximo y lo agrega a RFinal2 en caso positivo
	esMax(Nombre,Puntos,Max,Nombre2),
	append(Nombre2,RFinal,RFinal2)
	.
puntos_max([],Temp,Temp,[]).%Caso base

esMax(_,Puntos,Max,[]):-
	%predicado auxiliar de puntos_max
	Puntos < Max.
esMax(Nombre,Puntos,Max,[Nombre]):-
	Puntos >= Max.

%Punto por mayor número de cartas
sumar_puntos(Players,Players5):-
	%Sumar punto al que tiene mas cartas obtenidas, sólo si hay uno solo con la maxima cantidad
	%Los puntos de las escobas hechas se sumaron durante la ronda de jugar_jugador
	% format("empezar sumar puntos: ~w~n",[Players]),
	% Tercer parámetro enviado: c para contar cantidad de cartas, s para cantidad de sietes y o para cantidad de oros
	imprimir_escobas(Players),
	maxima_cantidad_cartas(Players,L1,c),
	maxima_cantidad_cartas(Players,L2,s),
	maxima_cantidad_cartas(Players,L3,o),
	quien_tiene_siete_oro(Players,PlayerOro),
	sumar_punto(Players,L1,Players2,c),
	sumar_punto(Players2,L2,Players3,s),
	sumar_punto(Players3,L3,Players4,o),
	sumar_punto(Players4,PlayerOro,Players5,so).

sumar_punto(Players,ListaMaximos,Players3,Tipo):-
	%Si ListaMaximos tiene un solo jugador, se le suma un punto a dicho jugador y se retorna en Players3
	ListaMaximos=[player(Nombre,_,_,_,_)],
	select(player(Nombre,Baraja,Traidas,Puntos,WS),Players,Players2),
	Puntos2 is Puntos+1,
	Players3=[player(Nombre,Baraja,Traidas,Puntos2,WS)|Players2],
	imprimirPunto(Nombre,Tipo)
	.
sumar_punto(Players,ListaMaximos,Players,_):-
	%Si hay mas de un jugador con un maximo en algo, hay empate y no se suma punto, la lista de jugadores queda igual
	length(ListaMaximos,R),
	R>1;
	%Si no hay un jugador con un maximo no se hace nada
	length(ListaMaximos,R),
	R=0.

%Imprimir las escobas obtenidas (antes de empezar a sumar el resto de puntos)
imprimir_escobas([Player|Resto]):-
	Player=player(Nombre,_,_,Escobas,_),
	format("~w tiene ~w escobas ~n",[Nombre,Escobas]),
	imprimir_escobas(Resto).
imprimir_escobas([]).

%Mostrar los puntos obtenidos en pantalla
imprimirPunto(Nombre,Tipo):-
	Tipo=c,
	format("Punto por más cantidad de cartas: ~w~n",[Nombre]).
imprimirPunto(Nombre,Tipo):-
	Tipo=s,
	format("Punto por más cantidad de sietes: ~w~n",[Nombre]).
imprimirPunto(Nombre,Tipo):-
	Tipo=o,
	format("Punto por más cantidad de oros: ~w~n",[Nombre]).
imprimirPunto(Nombre,Tipo):-
	Tipo=so,
	format("Punto por tener el oro-7: ~w~n",[Nombre]).

maxima_cantidad_cartas(Players,L2,Tipo):-
	maxima_cant_aux(Players,0,_,L2,Tipo).

maxima_cant_aux([Player|Resto],TempCant,Max,L2,Tipo):-
	cant_cartas(Player,TempCant2,Tipo),%El Tipo permite contar cantidad de cartas,
	%contar cantidad de oros o de sietes sin tener que repetir el código de este predicado
	%para cada caso:
	%c para cartas,
	%o para contar oros,
	%s para contar sietes
	TempCant2>=TempCant,
	maxima_cant_aux(Resto,TempCant2,Max,L,Tipo),

	%Verificar a la vuelta de la cadena de llamadas si TempCant2 es igual al máximo
	verificar_maximo(TempCant2,Max,Player,Player2),
	append(Player2,L,L2). %Si no es el maximo, Player2 es vacío y la lista no se modifica

maxima_cant_aux([Player|Resto],Temp,Max,L,Tipo):-
	%Caso negativo, Temp2 no es máximo y sigue llamando sin cambios
	cant_cartas(Player,Temp2,Tipo),
	Temp2<Temp,
	maxima_cant_aux(Resto,Temp,Max,L,Tipo).

maxima_cant_aux([],Max,Max,[], _).

%Si Temp es maximo, retorna Player si no retorna lista vacía
verificar_maximo(Temp,Max,_,[]):-
	Temp<Max.
verificar_maximo(Temp,Max,Player,[Player]):-
	Temp>=Max.

cant_cartas(Player,ResCantCartas,Tipo):-
	%Cuenta la cantidad de cartas según el Tipo especificado
	Tipo=c,
	Player=player(_,_,Traidas,_,_),
	length(Traidas,ResCantCartas).

%Cantidad de oros dada una lista de cartas
cant_cartas(Player,R,Tipo):-
	%Cantidad de oros dada una lista de cartas
	Tipo=o,%oros
	Player=player(_,_,Traidas,_,_),
	cant_oros_aux(Traidas,0,R).

%Cantidad de sietes dada una lista de cartas
cant_cartas(Player,R,Tipo):-
	Tipo=s,%sietes
	Player=player(_,_,Traidas,_,_),
	cant_sietes_aux(Traidas,0,R).

cant_oros_aux([Carta|Rest],Temp,R):-
	%Contar la cantidad de oros
	Carta=oro-_,
	Temp2 is Temp+1,
	cant_oros_aux(Rest,Temp2,R).
cant_oros_aux([Carta|Rest],Temp,R):-
	Carta\=oro-_,
	cant_oros_aux(Rest,Temp,R).
cant_oros_aux([],Res,Res).

cant_sietes_aux([Carta|Rest],Temp,R):-
	Carta=_-7,
	Temp2 is Temp+1,
	cant_sietes_aux(Rest,Temp2,R).
cant_sietes_aux([Carta|Rest],Temp,R):-
	Carta\=_-7,
	cant_sietes_aux(Rest,Temp,R).
cant_sietes_aux([],Res,Res).

quien_tiene_siete_oro([Player|Resto],Res):-
	%Recorre la lista de Players hasta encontrar alguno que tiene 7 de oro (solo uno solo lo puede tener)
	Player=player(_,_,Traidas,_,_),
	\+tiene_siete_oro(Traidas),
	quien_tiene_siete_oro(Resto,Res).
quien_tiene_siete_oro([Player|_],[Player]):-
	Player=player(_,_,Traidas,_,_),
	tiene_siete_oro(Traidas)
	.
quien_tiene_siete_oro([],[]). %Caso base: ninguno tiene el 7 de oro
tiene_siete_oro([Carta|_]):-
	Carta=oro-7.
tiene_siete_oro([Carta|Resto]):-
	Carta\=oro-7,
	tiene_siete_oro(Resto)
	.
