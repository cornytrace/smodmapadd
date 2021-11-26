# .SNL File Format

## Node Format:
```
N "hint_type node_type x y z yaw"
```

Where node_type is one of the following numbers:
```
NODE_TYPE_GROUND = 2
NODE_TYPE_AIR = 3
NODE_TYPE_CLIMB = 4
NODE_TYPE_WATER = 5
```

## Link format:
```
link_type "src_id dest_id ai_move_type"
```
### link_type:
- L - new node to new node
- I - new node to nodegraph node
- O - nodegraph node to new node

A link type of "L" links two nodes from the "Node Format" list, and a link_type of "I" links a node from the "Node Format" list to the existing nodes in the map.

### ai_move_type:
One of the following bits:
```
MOVE_GROUND = 1
MOVE_JUMP = 2
MOVE_FLY = 4
MOVE_CLIMB = 8
MOVE_SWIM = 16
MOVE_CRAWL = 32
```
While normally these bits are added together to combine them, in .snl the line is specified twice with different ai_move_types.

ai_move_type apparently applies to all hull types.

## File format:
```
"Node Format" lines
-
"Link Format" lines
-
```
