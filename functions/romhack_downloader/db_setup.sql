.nullvalue NULL

DROP TABLE IF EXISTS base;
DROP TABLE IF EXISTS rhack;

CREATE TABLE base (
        system TEXT NOT NULL, -- e.g. 'nes' or 'n64'
        name TEXT NOT NULL, -- full name, e.g. "Super Mario Bros."
        region TEXT NOT NULL, -- 'U' (USA), 'E' (Europe), 'J' (Japan) or 'W' (World)
        version TEXT NOT NULL, -- normally '1.0'; revision 1 is '1.1' etc.
        hash TEXT NOT NULL PRIMARY KEY, -- crc32
        local_path TEXT
);

CREATE TABLE rhack (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        base_hash TEXT NOT NULL,
        name TEXT NOT NULL,
        author TEXT NOT NULL,
        type TEXT, -- e.g. 'English translation'; put NULL when original hack
        released TEXT, -- 'YYYY-MM-DD'; if e.g. only year and month is available do 'YYYY-MM'
        version TEXT NOT NULL, -- e.g. '1.0'
        retro_achievements TEXT NOT NULL, -- 'yes' or 'no'
        url TEXT, -- direct download link; always prefer patches provided by RetroAchievements, if available
        archive_path TEXT, -- path of the patch file inside the archive, e.g. 'patches/v1.bps'
        description TEXT, -- place the whole text on a single line, no line break
        FOREIGN KEY (base_hash) REFERENCES base (hash)
);

-----------------------------------------------------------
--- ROM Hacks
-----------------------------------------------------------

-- Base ROMs. Order these alphabetically; left-most element is most important for ordering, then next to left-most etc.
INSERT INTO base (system, name, region, version, hash) VALUES
('gba', 'Tomato Adventure', 'J', '1.0', 'e37ca939'),
('n64', 'Super Mario 64', 'U', '1.0', '3ce60709'),
('n64', 'The Legend of Zelda - Ocarina of Time', 'U', '1.2', 'cd16c529'),
('nes', 'Super Mario Bros.', 'W', '1.0', '393a432f'),
('snes', 'Super Mario World', 'U', '1.0', 'b19ed489')
;

-- ROM Hacks. Follow ordering of base table above, so group by system first, then name of base game etc.
INSERT INTO rhack (base_hash, name, type, version, author, released, retro_achievements, url, archive_path, description) VALUES
-- Super Mario 64
('3ce60709', 'Super Mario 64 (U)', 'Randomizer', '1.1.2', 'Arthurtilly', NULL, 'yes', 'https://github.com/RetroAchievements/RAPatches/raw/main/N64/Hacks/Super%20Mario%2064/10509-SM64-Randomizer.zip', 'SM64 - Randomizer (v1.1.2) (Arthurtilly).bps', NULL),
('3ce60709', 'Super Mario Bros. 64', NULL, '1.1', 'Kaze Emanuar', '2018-12-21', 'yes', 'https://github.com/RetroAchievements/RAPatches/raw/main/N64/Hacks/Super%20Mario%2064/13831-SM64-SMB64.7z', 'SM64 - Super Mario Bros. 64 (Kaze Emanuar).bps', 'Super Mario Bros. 64 allows you to play through 30 classic NES Super Mario Bros recreated in the Mario 64 game engine. You get infinite lives to play through the game, but are given a ‘Par’ for each level, referring to the amount of lives an average player should lose per level, and you earn points for losing as few lives as possible. There are four playable characters (Mario, Luigi, Wario and Luigi), each of which has their own unique jump height which can make the game harder or easier (we’d recommend Wario or Luigi for your first playthrough).'),
-- Super Mario Bros.
('393a432f', 'Super Mario Unlimited Deluxe', NULL, '2.4', 'frantik', '2021-03-26', 'yes', 'https://github.com/RetroAchievements/RAPatches/raw/main/NES/Hacks/Super%20Mario%20Bros/9904-SMB1-UnlimitedDeluxe.zip', 'SMB1 - Super Mario Unlimited - Deluxe (v2.4) (frantik).ips', 'Super Mario Unlimited Deluxe is a traditional-style Mario hack with difficulty ramping up from beginner to expert. It is based on the Super Mario Bros engine, but has been completely reworked into a whole new adventure.'),
-- Super Mario World
('b19ed489', 'New Super Mario World 2: Around The World', NULL, '1.3', 'Pink Gold Peach', '2019-12-10', 'yes', 'https://github.com/RetroAchievements/RAPatches/raw/main/SNES/Hacks/Super%20Mario%20World/16121-NSMW2AroundtheWorld.zip', 'SMW - New Super Mario World 2 - Around the World (v1.3) (Pink Gold Peach).bps', 'The sequel to NSMW1 The 12 Magic Orbs, this hack features 16 different worlds and 90+ unique levels filled with challenge and secrets. The hack uses a lot of ASM like custom sprites, blocks, uberASM effects and other stuff like that. Aesthetically it has a choconilla style with most of the graphics being from the original SMW with some new custom graphics.'),
('b19ed489', 'Yoshi''s Strange Quest', NULL, '1.3', 'Yoshifanatic', '2015-03-07', 'no', 'https://github.com/RetroAchievements/RAPatches/raw/main/SNES/Hacks/Super%20Mario%20World/8366-YoshisStrangeQuest.zip', 'SMW - Yoshi''s Strange Quest (v1.3) (Yoshifanatic).bps', 'This is the sequel to Mario''s Strange Quest. Picking up where Mario''s Strange Quest left off, it turns out that the part where Yoshi''s eggs hatched at the end of MSQ didn''t actually happen. What really happened after Mario beat Bowser, rescued Yoshi''s eggs, and saved the princess was that Yoshi and his sleepy friend decided to move to a new land so that he can protect his eggs from Bowser before they really hatched. So, both Yoshis do so and they find themselves in the land of Weirdonia. However, it seems that Bowser apparently insists on stealing Yoshi''s eggs, since Yoshi''s eggs were stolen again while Yoshi was out shopping. Since Mario isn''t around to help this time, Yoshi goes on a quest by himself to retrieve his eggs. However, just like Mario''s Strange Quest, this isn''t your ordinary quest. The land of Weirdonia is a strange land filled with bizarre gimmicks, weird themes, and possibly jelly filled donuts and pizza. Expect the unexpected during Yoshi''s journey.'),
-- Tomato Adventure
('e37ca939', 'Tomato Adventure (J)', 'English translation', '1.1.1', 'Unknown W. Brackets', '2021-06-17', 'yes', 'https://github.com/RetroAchievements/RAPatches/raw/main/GBA/Translation/English/9802-TomatoAdv-EnglishTranslation.zip', 'Tomato Adventure (Japan) (En) (v1.1.1) (Unknown W. Brackets).bps', NULL)
;
