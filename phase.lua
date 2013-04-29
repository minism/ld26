local clr = {
    {
        {36, 182, 255},
        {255, 54, 87},
        {70, 255, 54},
        bg={255,255,255},
    },
    {
        {86, 145, 98},
        {217, 174, 48},
        {217, 21, 41},
        bg={255,200,200},
    },
    {
        {29, 204, 74},
        {255, 161, 37},
        {116, 11, 255},
        bg={200,255,200},
    },
    {
        {192, 210, 219},
        {244, 146, 30},
        {62, 107, 133},
        {158, 0, 244},
        bg={61,4,89},
    },
    {
        {36, 182, 255},
        {255, 54, 87},
        {70, 255, 54},
        {192, 210, 219},
        bg={255,255,255},
    },
}


phases = {
    {
        pushrate = {6, 12},
        colors = clr[1],
        color_limit = 2,
    },
    {
        pushrate = {6, 12},
        droprate = {4, 7},
        colors = clr[1],
        color_limit = 2,
    },
    {
        pushrate = {6, 12},
        droprate = {3, 6},
        colors = clr[1],
    },

    {
        droprate = {1, 2},
        colors = clr[2],
        color_limit = 2,
    },
    {
        droprate = {2, 4},
        pushrate = {5, 10},
        bombchance = 1 / 10,
        colors = clr[2],
    },
    {
        droprate = {1, 3},
        pushrate = {5, 10},
        bombchance = 1 / 12,
        colors = clr[2],
    },

    {
        pushrate = {4, 8},
        batrate  = {4, 8},
        colors = clr[3],
    },
    {
        droprate = {4, 6},
        pushrate = {3, 6},
        batrate  = {3, 7},
        colors = clr[3],
        bombchance = 1 / 6,
    },
    {
        droprate = {0.75, 1.5},
        batrate  = {4, 8},
        colors = clr[3],
        bombchance = 1 / 16,
    },

    {
        pushrate = {3, 5},
        colors = clr[4],
    },
    {
        droprate = {2, 4.5},
        pushrate = {2, 4.5},
        colors = clr[4],
        bombchance = 1 / 5,
    },
    {
        batrate = {2, 4},
        pushrate = {3, 6},
        colors = clr[4],
    },
    {
        batrate = {3, 6},
        droprate = {0.5, 0.75},
        bombchance = 1 / 16,
        colors = clr[4]
    },
    {
        -- batrate = {0.4, 0.8},
        droprate = {0.4, 0.8},
        bombchance = 1 / 24,
        colors = clr[4]
    },


    -- Infinite level
    {
        batrate = {3, 6},
        droprate = {2, 4},
        pushrate = {2, 4},
        bombchance = 1 / 16,
        colors = clr[5],
    }
}

