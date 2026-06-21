%prolog
:- module(servidorjuego, [main/0]).

:- use_module(library(http/websocket)).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(lists), [member/2]).
:- use_module(library(http/http_files)).
:- consult('./tpo1/escoba.pl').

:- dynamic(players/1).
:- dynamic(juego/1).

%------------------------Ser vir el directorio de archivos y acceder a http://localhost:8888/index.html para acceder al cliente web
:- http_handler(root(.), http_reply_from_files('.', []), [prefix]).

server(Port) :-
    http_server(http_dispatch, [port(Port)]).

serve :-
    server(8888).
:- serve.
%------------------------

main :-
	thread_self(MainThread),
    asserta(main_thread(MainThread)),
    http_server(http_dispatch, [port(8316)]),
    format('Servidor genérico escuchando en puerto 8316...~n', []),
    esperar_fin_juego.


esperar_fin_juego :-
    thread_get_message(fin_juego),
	format("Servidor terminando...~n", []),
	halt
    .

:- http_handler(root(ws), http_upgrade_to_websocket(procesar_player, []), [spawn([])]).

%------------------------------------------------------
procesar_player(WebSocket) :-
    ws_receive(WebSocket, Message, [format(prolog)]),
    format("Recibido: ~w~n", [Message]),
    (   Message.data = join(Nombre) ->
        agregar_player(Nombre, WebSocket),
        verificar_inicio
    ;   ws_send(WebSocket, text("Envía join(tu_nombre)"))
    ),
    mantener_activo.

agregar_player(Nombre, WebSocket) :-
    (   players(Lista) ->
        retract(players(Lista)) % borra la lista para volver a concatenarla con el nuevo par  player(Nombre, WebSocket)
    ;   Lista = []
    ),
    NuevaLista = [player(Nombre, WebSocket)|Lista], %Asocia cada player a su WebSocket
    assertz(players(NuevaLista)),
    length(NuevaLista, Cant),
    format("Jugador ~w conectado. Total: ~w~n", [Nombre, Cant]),
	ws_send(WebSocket,text("conectado correctamente")).

%------------------------------------------------------
verificar_inicio :-
    players(Lista),
    length(Lista, 2), % Solo 2 players para prueba
    !,
    assertz(juego(iniciado)),
    format("Iniciando juego con ~w players~n", [2]),
    forall(member(player(_, WS), Lista),
    ws_send(WS, text("¡Juego iniciado!"))),
	escoba(Lista).
verificar_inicio :-
    players(Lista),
    forall(member(player(_, WS), Lista),ws_send(WS, text("esperando más players"))).  
	   %Enviar a todos los websockers el mensaje de esperando más players
%------------------------------------------------------
mantener_activo :-
    % (   juego(terminado) ->
    %     format("Hilo terminando para websocket~n", [])
    % ;   
	% mantener_activo
	thread_self(CurrentThread),
    % set_thread(CurrentThread, alias(thread_ws)),
    thread_get_message(fin_juego),
	format("Servidor terminando...~n", [])
    .
    
%------------------------------------------------------
:- main.
