// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

// Module: collectible
module collectible::moment {

    use std::string::{String, utf8};
    use sui::url;

    // moment information for a token
    public struct Moment has store, copy, drop {
        team: String,
        player: String,
        date: String,            // date of the game
        play: String,            // type of play e.g. goal
        play_of_game: String,    // play of the game e.g. 1 of 3
        game_difficulty: String, // game difficulty e.g. easy
        game_clock: String,      // game clock e.g. 72:23
        audio_type: String,      // audio type
        video: url::Url,         // primary media
        total_editions: u32,     // total editions of this moment
    }

    public fun new_moment(
            team: vector<u8>,
            player: vector<u8>,
            date: vector<u8>,
            play: vector<u8>,
            play_of_game: vector<u8>,
            game_difficulty: vector<u8>,
            game_clock: vector<u8>,
            audio_type: vector<u8>,
            video: vector<u8>,
            total_editions: u32,
        ): Moment {
        Moment {
            team: utf8(team),
            player: utf8(player),
            date: utf8(date),
            play: utf8(play),
            play_of_game: utf8(play_of_game),
            game_difficulty: utf8(game_difficulty),
            game_clock: utf8(game_clock),
            audio_type: utf8(audio_type),
            video: url::new_unsafe_from_bytes(video),
            total_editions: total_editions,
        }
    }

    // === Public getter functions ===

    public fun team(self: &Moment): String {
        self.team
    }

    public fun player(self: &Moment): String {
        self.player
    }

    public fun date(self: &Moment): String {
        self.date
    }

    public fun play(self: &Moment): String {
        self.play
    }

    public fun play_of_game(self: &Moment): String {
        self.play_of_game
    }

    public fun game_clock(self: &Moment): String {
        self.game_clock
    }

    public fun game_difficulty(self: &Moment): String {
        self.game_difficulty
    }

    public fun audio_type(self: &Moment): String {
        self.audio_type
    }

    public fun video(self: &Moment): String {
        utf8(*self.video.inner_url().as_bytes())
    }

    public fun total_editions(self: &Moment): u32 {
        self.total_editions
    }

    // === public setter functions ====

    public fun update(
        self: &mut Moment,
        new_moment: &Moment,
    ) {
        self.audio_type = new_moment.audio_type;
        self.date = new_moment.date;
        self.game_clock = new_moment.game_clock;
        self.game_difficulty = new_moment.game_difficulty;
        self.play = new_moment.play;
        self.play_of_game = new_moment.play_of_game;
        self.player = new_moment.player;
        self.team = new_moment.team;
        self.total_editions = new_moment.total_editions;
        self.video = new_moment.video;
    }

    public fun update_team(
        self: &mut Moment,
        new_team: vector<u8>,
    ) {
        self.team = utf8(new_team);
    }

    public fun update_player(
        self: &mut Moment,
        new_player: vector<u8>,
    ) {
        self.player = utf8(new_player);
    }

    public fun update_date(
        self: &mut Moment,
        new_date: vector<u8>,
    ) {
        self.date = utf8(new_date);
    }

    public fun update_play(
        self: &mut Moment,
        new_play: vector<u8>,
    ) {
        self.play = utf8(new_play);
    }

    public fun update_play_of_game(
        self: &mut Moment,
        new_play_of_game: vector<u8>,
    ) {
        self.play_of_game = utf8(new_play_of_game);
    }

    public fun update_game_difficulty(
        self: &mut Moment,
        new_game_difficulty: vector<u8>,
    ) {
        self.game_difficulty = utf8(new_game_difficulty);
    }

    public fun update_game_clock(
        self: &mut Moment,
        new_game_clock: vector<u8>,
    ) {
        self.game_clock = utf8(new_game_clock);
    }

    public fun update_audio_type(
        self: &mut Moment,
        new_audio_type: vector<u8>,
    ) {
        self.audio_type = utf8(new_audio_type);
    }
    public fun update_video(
        self: &mut Moment,
        new_video: vector<u8>,
    ) {
        self.video = url::new_unsafe_from_bytes(new_video);
    }

    public fun update_total_editions(
        self: &mut Moment,
        new_total_editions: u32,
    ) {
        self.total_editions = new_total_editions;
    }

}
