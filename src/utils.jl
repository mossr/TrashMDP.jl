## Utility functions

# Linear/Cartesian index helpers
CI(i) = [CartesianIndices((WORLD_X, WORLD_Y))[i].I...]
LI(xy) = LinearIndices((WORLD_X, WORLD_Y))[xy...]
LI(x,y) = LI([x,y])

# Manhattan distance
manhattan(p1,p2) = sqrt(sum((p1 - p2) .^ 2))