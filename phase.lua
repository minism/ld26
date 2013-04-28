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
}


phases = {
    {
        pushrate = {5, 10},
        colors = clr[1],
        color_limit = 2,
    },
    {
        pushrate = {6, 12},
        droprate = {3, 6},
        colors = clr[1],
        color_limit = 2,
    },
    {
        pushrate = {6, 12},
        droprate = {3, 6},
        colors = clr[1],
    },
    {
        droprate = {3, 6},
        pushrate = {4, 8},
        colors = clr[2],
    },
    {
        batrate = {5, 10},
        droprate = {3, 6},
        pushrate = {4, 8},
        colors = clr[2],
    },
}

