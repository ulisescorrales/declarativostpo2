%prolog
%Todos los format los imprime el server y los ws_send el jugador del turno
%Los read ahora son ws_receive
:- use_module(library(random)).
:- use_module(library(clpfd)).
state(S), [S] --> [S].
state(S0, S), [S] --> [S0].

card(Suite-Number) :-
    % member(Suite, [oro,espada,copa,palo]),
    % member(Number, [rey, caballo, sota, 7, 6, 5, 4, 3, 2, as]).
    member(Suite, [oro,espada]),
    member(Number, [rey, 3, 2]).
%Nombre de cartas disponibles

%Puntaje de cada carta
card_score(_-as,1).
card_score(_-X,X):-member(X,[7,6,5,4,3,2]).
card_score(_-sota,8).
card_score(_-caballo,9).
card_score(_-rey,10).



jugar_jugador(CartasMesa,Player,CartasMesa2,Player2)-->
	%Estado de inicio para la ronde del jugador
	{
		Player=[Nombre,_,_,_,WS],
		format("Turno de ~w~n",[Nombre]),
		ws_send(WS,text("Tu turno"))
	},
	reset_jugador(CartasMesa,Player,CartasMesa2,Player2),
	elegir_carta_baraja(CartasMesa,Player,CartasMesa2,Player2),
	opcion_carta_baraja(CartasMesa,Player,CartasMesa2,Player2),
	notificar_siguiente(Player).
reset_jugador(CartasMesa,Player,_,_) -->
	%Estado inicial del turno del jugador
	% state(J0,[opcionElegida(_),cartasElegidas([_])]).
	state(_,[cartasMesa(CartasMesa),opcionElegida(_),cartaElegidaBaraja(_)]),
	{
		Player=[_,_,_,_,WS],
		format(string(Mensaje),"Cartas en la mesa disponibles: ~w~n",[CartasMesa]),
		ws_send(WS,text(Mensaje))
		% format("en reset_jugador~n")
	}
	.
elegir_carta_baraja(_,Player,_,_)-->
	%Elegir la carta de la baraja que tiene en sus manos el jugador
	state(J0,J),
	{
		Player=[_,Baraja,_,_,WS],
		format(string(Mensaje),"Eliga carta de la baraja: ~w~n",[Baraja]),
		ws_send(WS,text(Mensaje)),
		%forzar el read en el cliente
		ws_send(WS,text("elegir")),
    	ws_receive(WS, Recibido, [format(prolog)]),
		Opcion=Recibido.data,
		format("Opción recibida:~w~n",[Opcion]),
		member(Opcion,Baraja),
		select(cartaElegidaBaraja(_),J0,J1),
		J=[cartasElegidas([Opcion]),cartaElegidaBaraja(Opcion)|J1],
		format("Carta elegida: ~w~n",[Opcion]),
		format(string(Mensaje2),"Carta elegida: ~w~n",[Opcion]),
		ws_send(WS,text(Mensaje2))
	}.
elegir_carta_baraja(C,P,C2,P2)-->
	%Predicado hecho en caso de elegir una carta inválida en la elección de cartas de la baraja
	{
		P=[_,_,_,_,WS],
		format("Carta recibida inválida~n"),
		format(string(Mensaje),"Carta de la baraja invalida, vuelva a intentarlo~n",[]),
		ws_send(WS,text(Mensaje))
	},
	elegir_carta_baraja(C,P,C2,P2).

opcion_carta_baraja(C,P,C2,P2) -->
	%Mostrar mensaje de opciones después de elegir una carta de la baraja 
	state(J0,J),
	{
		format("Jugador elige opción~n"),
		P=[_,_,_,_,WS],
		format(
			string(Msg),
			"Elija una opcion:~n\
			 t para tirar~n\
			 m para elegir cartas de la mesa~n\
			 a para elegir otra carta de la baraja",
			[]
		),
		ws_send(WS, text(Msg)),
		%Pedir el read en el cliente
		ws_send(WS,text("elegir")),
    	ws_receive(WS, Recibido, [format(prolog)]),
		Opcion=Recibido.data,
		format("Opción elegida: ~w~n",[Opcion]),
		select(opcionElegida(_),J0,J1),
		J=[opcionElegida(Opcion)|J1]
	},
	evaluar_opcion_elegida(C,P,C2,P2)
	.
%Leer la opción elegida y actuar según su valor:
evaluar_opcion_elegida(C,P,C2,P2) -->
	state(J),
	{
		member(opcionElegida(Opcion),J),
		\+ member(Opcion,[t,m,a]),
		P=[_,_,_,_,WS],
		format("Opcion incorrecta: ~w~n",[J]),
		ws_send(WS,text("Opcion incorrecta, vuelva a intentarlo"))
	},
	opcion_carta_baraja(C,P,C2,P2)
	.
evaluar_opcion_elegida(C,P,C2,P2) -->
	state(J),
	{
		member(opcionElegida(t),J),
		format("Opción elegida: tirar carta a la mesa~n"),
		P=[_,_,_,_,WS],
		ws_send(WS,text("Opción elegida: tirar carta a la mesa"))
	},
	tirar_mesa(C,P,C2,P2)
	.
evaluar_opcion_elegida(C,P,C2,P2) -->
	state(J0),
	{
		member(opcionElegida(Opcion),J0),
		Opcion = a,
		format("Opcion elegida: abortar, ~w~n",[Opcion]),
		P=[_,_,_,_,WS],
		ws_send(WS,text("Opcion elegida: abortar"))
	},
	jugar_jugador(C,P,C2,P2)
	.
evaluar_opcion_elegida(C,P,C2,P2) -->
	state(J),
	{
		P=[_,_,_,_,WS],
		member(opcionElegida(Opcion),J),
		Opcion=m,
		format("Opción elegida: agarrar cartas de la mesa~n"),
		ws_send(WS,text("Opción elegida: agarrar cartas de la mesa"))
	},
	elegir_cartas_mesa(C,P,C2,P2)
	.
tirar_mesa(C,P,C2,P2)-->
	%Acción de tirar a la mesa la carta de la baraja elegida
	state(J0),
	{
		member(cartasElegidas(X),J0),
		length(X,1),
		append(X,C,C2),
		P=[Name,Baraja,Traidas,Puntos,_],
		subtract(Baraja,X,Baraja2),
		P2=[Name,Baraja2,Traidas,Puntos,_]
		}.
elegir_cartas_mesa(C,P,C2,P2)-->
	%Si al elegir cartas de la mesa ya no quedan más, reiniciar ronda
	state(J0),
	{
		member(cartasMesa(CartasMesa),J0),
		length(CartasMesa,L),
		L=0,
		P=[_,_,_,_,WS],
		format("No hay mas cartas en la mesa para tomar y no sumaron 15. ~n"),
		ws_send(WS,text("No hay mas cartas en la mesa para tomar y no sumaron 15. ~n"))
	},
	jugar_jugador(C,P,C2,P2)
	.
elegir_cartas_mesa(C,P,C2,P2) -->
	%Elegir cartas disponibles en la mesa para intentar sumar 15 puntos y llevarlas
	state(S0,S),
	{
		select(opcionElegida(_),S0,S1),
		member(cartasMesa(CartasMesa),S1),
		format("Elegir carta de la mesa~n"),
		P=[_,_,_,_,WS],
		format(string(Mensaje),"Elija cartas en la mesa: ~w, a para volver a elegir a elegir una carta de la baraja~n",[CartasMesa]),
		ws_send(WS,text(Mensaje)),
		%forzar el read en el cliente
		ws_send(WS,text("elegir")),
    	ws_receive(WS,  Recibido, [format(prolog)]),
		CartaElegida=Recibido.data,
		format("Carta de la mesa elegida: ~w~n",[CartaElegida]),
		S=[opcionElegida(CartaElegida)|S1]
	},
	evaluar_opcion_cartas_mesa(C,P,C2,P2)
	.

evaluar_opcion_cartas_mesa(C,P,C2,P2)-->
	%Al elegir carta de la mesa, verificar que esté en la mesa
	state(J0),
	{
		member(opcionElegida(CartaElegida),J0),
		member(cartasMesa(CartasMesa),J0),
		member(CartaElegida,CartasMesa),
		format("Carta elegida: ~w~n",[CartaElegida])
	},
	evaluar_sumatoria(C,P,C2,P2)
	.
evaluar_opcion_cartas_mesa(C,P,C2,P2)-->
	%Caso: carta elegida inexistente
	state(J),
	{
		P=[_,_,_,_,WS],
		member(opcionElegida(CartaElegida),J),
		member(cartasMesa(CartasMesa),J),
		\+member(CartaElegida,[a|CartasMesa]),
		format("opción incorrecta~n"),
		ws_send(WS,text("Opcion incorrecta, vuelva a intentarlo"))
	},
	elegir_cartas_mesa(C,P,C2,P2).
evaluar_opcion_cartas_mesa(C,P,C2,P2)-->
	%Caso abortar, resetear
	state(J),
	{
		member(opcionElegida(Opcion),J),
		Opcion=a,
		format("Reiniciar~n"),
		P=[_,_,_,_,WS],
		ws_send(WS,text("Reiniciar"))
	},
	jugar_jugador(C,P,C2,P2).

evaluar_sumatoria(C,P,C2,P2)-->
	%Después de elegir una carta correcta, se debe verificar la sumatoria de puntos hasta el momento. Si suma 15, termina la ronda; si es menor, se sigue eligiendo; y si es mayor, reiniciar.
	state(J0,J),
	{
		member(opcionElegida(CartaElegida),J0),
		select(cartasElegidas(Elegidas),J0,J1),
		select(cartasMesa(CartasMesa),J1,J2),
		TempElegidas=[CartaElegida|Elegidas],
		sumatoria(TempElegidas,R),
		R<15,
		subtract(CartasMesa,[CartaElegida],CartasMesa2),

		J=[cartasElegidas(TempElegidas),cartasMesa(CartasMesa2)|J2],
		P=[_,_,_,_,WS],
		format("Seguir eligiendo~n"),
		format(string(Mensaje),"Las cartas eligidas suman ~w puntos. Seguir eligiendo.~n",[R]),
		ws_send(WS,text(Mensaje))
	},
	elegir_cartas_mesa(C,P,C2,P2)
	.

evaluar_sumatoria(C,P,C2,P2)-->
	%Caso: es mayor a 15, reinicia y vuelve a elegir de la baraja
	state(J),
	{
		member(cartasElegidas(Elegidas),J),
		member(opcionElegida(CartaElegida),J),
		sumatoria([CartaElegida|Elegidas],R),
		R>15,
		format("Cartas suman mas de quince puntos: ~w, reiniciar ~n",[R]),
		P=[_,_,_,_,WS],
		format(string(Mensaje),"Cartas suman mas de quince puntos: ~w, reiniciar ~n",[R])
		,ws_send(WS,text(Mensaje))
	},
	jugar_jugador(C,P,C2,P2)
	.
evaluar_sumatoria(C,P,C2,P2)-->
	%Caso: las  cartas elegidas suman 15, terminar selección de cartas
	state(J0,J),
	{
		member(cartasElegidas(Elegidas),J0),
		member(opcionElegida(CartaElegida),J0),
		sumatoria([CartaElegida|Elegidas],R),
		R=15,
		P=[Nombre,Baraja,Traidas,_,WS],
		format("Cartas elegidas suman 15 puntos. Termina ronda de jugador ~w~n",[Nombre]),
		ws_send(WS,text("Cartas elegidas suma 15 puntos. Termina su ronda")),
		select(cartasElegidas(Elegidas),J0,J1),

		%Baraja restante
		member(cartaElegidaBaraja(CartaBaraja),J1),
		subtract(Baraja,[CartaBaraja],Baraja2),
		%Traidas resultante
		append([CartaElegida|Elegidas],Traidas,Traidas2),

		%Cartas Mesa restantes
		select(cartasMesa(CartasMesa),J1,J2),
		subtract(CartasMesa,[CartaElegida],CartasMesa2),
		J=[cartasElegidas([CartaElegida|Elegidas]),cartasMesa(CartasMesa2)|J2],
		%
		C2=CartasMesa2,
		P2=[Nombre,Baraja2,Traidas2,_,_] %El puntaje se evalua en el siguiente paso

	},
	evaluar_escoba(C,P,C2,P2)
.
evaluar_escoba(_,P,_,P2)-->
	%Después de alcanzar 15 puntos eligiendo cartas; si hay escoba (CartasMesa es vacío), sumar un punto al jugador
	state(J),
	{
		member(cartasMesa(CartasMesa),J),
		length(CartasMesa,L),
		L=0,
		format("escoba!~n"),
		P=[_,_,_,Puntos,WS],
		ws_send(WS,text("escoba!")),
		Puntos2 is Puntos+1,
		P2=[_,_,_,Puntos2,WS]
	}.
evaluar_escoba(_,P,_,P2)-->
	%En caso que no haya escoba
	state(J),
	{
		member(cartasMesa(CartasMesa),J),
		length(CartasMesa,L),
		L>0,
		P=[_,_,_,Puntos,_],
		P2=[_,_,_,Puntos,_]
	}.

%Predicados para obtener la sumatoria de puntos de una lista de cartas
sumatoria(L,R):-
	sumatoriaAux(L,0,R).
sumatoriaAux([H|T],Temp,R):-
	card_score(H,S),
	Temp2 is Temp+S,
	sumatoriaAux(T,Temp2,R).
sumatoriaAux([],Temp,Temp).

notificar_siguiente(Player) -->
	state(S),
	{
		Player=[_,_,_,_,WS],
		ws_send(WS,text("Fin de la ronda, espere su turno"))
	}.
