#!/bin/bash

SESSION="dev"

# Crear sesión en segundo plano
tmux new-session -d -s $SESSION

# Split horizontal (arriba / abajo)
tmux split-window -v -t $SESSION
# pane 0.0 = arriba
# pane 0.1 = abajo

# Split vertical SOLO en el pane de arriba
tmux split-window -h -t $SESSION:0.0
# pane 0.2 = arriba-derecha (extra)

# Ejecutar comandos donde querés
tmux send-keys -t $SESSION:0.0 "swipl clientejuego.pl" C-m
# tmux send-keys -t $SESSION:0.0 "npm run start" C-m

tmux send-keys -t $SESSION:0.1 "swipl clientejuego.pl" C-m
# tmux send-keys -t $SESSION:0.1 "npm run dev" C-m

# tmux resize-pane -t $SESSION:0.2 -y 1
# Dejar el cursor en el pane 0.0
tmux send-keys -t $SESSION:0.2 "swipl servidorjuego.pl" C-m
tmux select-pane -t $SESSION:0.2

# Adjuntarse a la sesión
tmux attach -t $SESSION
