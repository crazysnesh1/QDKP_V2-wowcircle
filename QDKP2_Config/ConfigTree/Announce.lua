local L = QDKP2_Config.Localize

QDKP2_Config.Tree.args.Announce = {
    type = 'group',
    args = {
        AN_AnAwards = {
            type = 'toggle',
            order = 20,
        },
        AN_AnIM = {
            type = 'toggle',
            order = 30,
        },
        AN_AnPlChange = {
            type = 'toggle',
            order = 40,
        },
        AN_AnNegative = {
            type = 'toggle',
            order = 50,
        },
        AN_AnTimerTick = {
            type = 'toggle',
            order = 60,
        },
        AN_AnChannel = {
            type = 'select',
            values = { guild = L.AN_AnChannel1, raid = L.AN_AnChannel2, party = L.AN_AnChannel3, officer = L.AN_AnChannel4,
                       say = L.AN_AnChannel5, yell = L.AN_AnChannel6, raid_warning = L.AN_AnChannel7, battleground = L.AN_AnChannel8 },
            order = 70,
        },
        PushHeader = {
            type = 'header',
            order = 80,
        },
        AN_PushChanges = {
            type = 'toggle',
            order = 90,
        },
        AN_PushFailAw = {
            type = 'toggle',
            order = 100,
        },
        AN_PushFailHo = {
            type = 'toggle',
            order = 110,
        },
        AN_PushFailIM = {
            type = 'toggle',
            order = 120,
        },
        AN_PushModText = {
            type = 'input',
            order = 130,
            width = 'full',
        },
        AN_PushModReasText = {
            type = 'input',
            width = 'full',
            order = 140,
        },
        AN_PushRevText = {
            type = 'input',
            width = 'full',
            order = 150,
        },
    },
}
