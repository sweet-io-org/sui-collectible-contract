// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_moment {

    use std::debug;
    use std::string::{utf8, String};
    use collectible::moment::{
        Moment,
    };
    use collectible::test_common::{
        itos,
        build_string,
        get_new_moment,
        get_new_alt_moment,
    };

    #[test]
    fun test_moment_update() {
        let mut moment_data = get_new_moment();
        let alt_moment_data = get_new_alt_moment();
        debug_print_moment(utf8(b"Original Moment Data:"), &moment_data);
        debug_print_moment(utf8(b"Alt Moment Data:"), &alt_moment_data);
        // verify the whole doesn't match
        assert!(moment_data != alt_moment_data);
        // verify the parts don't match
        assert!(moment_data.team() != alt_moment_data.team());
        assert!(moment_data.player() != alt_moment_data.player());
        assert!(moment_data.date() != alt_moment_data.date());
        assert!(moment_data.play() != alt_moment_data.play());
        assert!(moment_data.play_of_game() != alt_moment_data.play_of_game());
        assert!(moment_data.game_difficulty() != alt_moment_data.game_difficulty());
        assert!(moment_data.game_difficulty() != alt_moment_data.game_difficulty());
        assert!(moment_data.video() != alt_moment_data.video());
        assert!(moment_data.total_editions() != alt_moment_data.total_editions());
        // update moment to match
        moment_data.update(&alt_moment_data);
        // verify the parts now match
        assert!(moment_data.team() == alt_moment_data.team());
        assert!(moment_data.player() == alt_moment_data.player());
        assert!(moment_data.date() == alt_moment_data.date());
        assert!(moment_data.play() == alt_moment_data.play());
        assert!(moment_data.play_of_game() == alt_moment_data.play_of_game());
        assert!(moment_data.game_difficulty() == alt_moment_data.game_difficulty());
        assert!(moment_data.game_difficulty() == alt_moment_data.game_difficulty());
        assert!(moment_data.video() == alt_moment_data.video());
        assert!(moment_data.total_editions() == alt_moment_data.total_editions());
        // Finally verify the whole now matches
        debug_print_moment(utf8(b"Modified Moment Data:"), &moment_data);
        assert!(moment_data == alt_moment_data);
    }

    #[test]
    fun test_moment_update_by_parts() {
        let mut moment_data = get_new_moment();
        let alt_moment_data = get_new_alt_moment();
        debug_print_moment(utf8(b"Original Moment Data:"), &moment_data);
        debug_print_moment(utf8(b"Alt Moment Data:"), &alt_moment_data);
        // verify the whole doesn't match
        assert!(moment_data != alt_moment_data);
        // verify the parts don't match
        assert!(moment_data.team() != alt_moment_data.team());
        assert!(moment_data.player() != alt_moment_data.player());
        assert!(moment_data.date() != alt_moment_data.date());
        assert!(moment_data.play() != alt_moment_data.play());
        assert!(moment_data.play_of_game() != alt_moment_data.play_of_game());
        assert!(moment_data.game_difficulty() != alt_moment_data.game_difficulty());
        assert!(moment_data.game_clock() != alt_moment_data.game_clock());
        assert!(moment_data.audio_type() != alt_moment_data.audio_type());
        assert!(moment_data.video() != alt_moment_data.video());
        assert!(moment_data.total_editions() != alt_moment_data.total_editions());
        // Update team to match alt
        moment_data.update_team(*alt_moment_data.team().bytes());
        assert!(moment_data.team() == alt_moment_data.team());
        // Update player name to match alt
        moment_data.update_player(*alt_moment_data.player().bytes());
        assert!(moment_data.player() == alt_moment_data.player());
        // Update game date to match alt
        moment_data.update_date(*alt_moment_data.date().bytes());
        assert!(moment_data.date() == alt_moment_data.date());
        // Update key play type to match alt
        moment_data.update_play(*alt_moment_data.play().bytes());
        assert!(moment_data.play() == alt_moment_data.play());
        // Update play of game to match alt
        moment_data.update_play_of_game(*alt_moment_data.play_of_game().bytes());
        assert!(moment_data.play_of_game() == alt_moment_data.play_of_game());
        // Update game difficulty to match alt
        moment_data.update_game_difficulty(*alt_moment_data.game_difficulty().bytes());
        assert!(moment_data.game_difficulty() == alt_moment_data.game_difficulty());
        // Update game clock to match alt
        moment_data.update_game_clock(*alt_moment_data.game_clock().bytes());
        assert!(moment_data.game_clock() == alt_moment_data.game_clock());
        // Update audio type to match alt
        moment_data.update_audio_type(*alt_moment_data.audio_type().bytes());
        assert!(moment_data.audio_type() == alt_moment_data.audio_type());
        // Update video URI to match alt
        moment_data.update_video(*alt_moment_data.video().bytes());
        assert!(moment_data.video() == alt_moment_data.video());
        // Update total editions to match alt
        moment_data.update_total_editions(alt_moment_data.total_editions());
        assert!(moment_data.total_editions() == alt_moment_data.total_editions());
        // Print the resulting data
        debug_print_moment(utf8(b"Modified Moment Data:"), &moment_data);
        assert!(moment_data == alt_moment_data);
    }

    fun debug_print_moment(name: String, moment: &Moment)
    {
        let mut debug_strs = vector::empty();
        debug::print(&name);
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Team: "), moment.team()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Player: "), moment.player()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Date: "), moment.date()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Play: "), moment.play()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Play of Game: "), moment.play_of_game()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Game Difficulty: "), moment.game_difficulty()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Game Clock: "), moment.game_clock()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Audio Type: "), moment.audio_type()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Video URI: "), moment.video()]));
        debug_strs.push_back(build_string(&mut vector[utf8(b" -- Total Editions: "), itos(moment.total_editions() as u256)]));
        // Print everything
        while (!debug_strs.is_empty()) {
            debug::print(&debug_strs.remove(0));
        }
    }
}
