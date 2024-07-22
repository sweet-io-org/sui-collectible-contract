// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_token {

    use std::debug;
    use std::string::{utf8};
    use sui::display;
    use sui::test_scenario;
    use collectible::moment;
    use collectible::register;
    use collectible::token;
    use collectible::test_common::{
        admin_burn_publisher,
        admin_create_new_display_template,
        admin_custom_display_template,
        admin_freeze_contract,
        admin_publish_contract,
        admin_register_new_minter,
        admin_revoke_minter_access,
        admin_transfer_admin_caps,
        build_string,
        check_last_receipt,
        get_alt_moment_data,
        get_alt_token_data,
        get_new_alt_moment,
        itos,
        owner_transfer_token,
    };

    // Integration tests

    #[test]
    fun test_mint_one_moment() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xDDDD;
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_update_display_template(&mut scenario, admin_addr,
            b"My Project Url",
            b"New Series", b"New Set", b"New Rarity");
        admin_mint_token(&mut scenario, 1, minter_addr, user1);
        admin_update_display_template(&mut scenario, admin_addr,
            b"My Project Url2",
            b"New Series2", b"New Set2", b"New Rarity2");
        owner_transfer_token<token::Token>(&mut scenario, user1, minter_addr);
        admin_update_token(&mut scenario, minter_addr,
            b"New name", b"New Description2",
            b"New PreviewImage2", 2);
        let alt_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, minter_addr, &alt_moment);
        admin_burn_token(&mut scenario, minter_addr);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = token::EInvalidRequest)]
    fun test_cannot_mint_edition_zero() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_update_display_template(&mut scenario, admin_addr,
            b"My Project Url",
            b"New Series", b"New Set", b"New Rarity");
        admin_mint_token(&mut scenario, 0, admin_addr, user1);
        scenario.end();
    }

    #[test]
    fun test_new_minter_flow() {
        let admin_addr = @0xAAAA;
        let minter1_addr = @0xBBBB;
        let minter2_addr = @0xCCCC;
        let user1 = @0xDDDD;
        let user2 = @0xEEEE;
        let mut scenario = test_scenario::begin(@0x0);
        // Verify that admin can create a new minter
        admin_publish_contract(&mut scenario, minter1_addr);
        admin_transfer_admin_caps(&mut scenario, minter1_addr, admin_addr);
        admin_register_new_minter(&mut scenario, admin_addr, minter2_addr);
        // Verify minter can mint a couple of tokens to user1
        admin_mint_token(&mut scenario, 1, minter2_addr, user1);
        admin_mint_token(&mut scenario, 2, minter2_addr, user2);
        // As one of the minters, freeze the contract
        admin_freeze_contract(&mut scenario, minter1_addr);
        // Verify that the users can transfer tokens back to a minter
        owner_transfer_token<token::Token>(&mut scenario, user1, minter1_addr);
        owner_transfer_token<token::Token>(&mut scenario, user2, minter1_addr);
        // Verify that the minter can burn both of the tokens (when ownership returned)
        admin_burn_token(&mut scenario, minter1_addr);
        admin_burn_token(&mut scenario, minter1_addr);
        scenario.end();
    }

    #[test]
    fun test_admin_minter_flow() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xCCCC;
        let user2 = @0xDDDD;
        // Admin publishes the contract and mints 2 tokens
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, user1);
        admin_mint_token(&mut scenario, 2, minter_addr, user2);
        // Freeze the contract as minter
        admin_freeze_contract(&mut scenario, minter_addr);
        // Users can still transfer the token back to admin
        owner_transfer_token<token::Token>(&mut scenario, user1, minter_addr);
        owner_transfer_token<token::Token>(&mut scenario, user2, minter_addr);
        // Admin can burn both of the tokens (when ownership returned)
        admin_burn_token(&mut scenario, minter_addr);
        admin_burn_token(&mut scenario, minter_addr);
        // Clean up
        scenario.end();
    }

    #[test]
    fun test_multi_minter_flow() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let minter1_addr = @0xCCCC;
        let minter2_addr = @0xDDDD;
        let user1 = @0x1111;
        let user2 = @0x2222;
        let user3 = @0x3333;
        let mut scenario = test_scenario::begin(@0x00);
        // Admin publishes the contract and create two minters
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_register_new_minter(&mut scenario, admin_addr, minter1_addr);
        admin_register_new_minter(&mut scenario, admin_addr, minter2_addr);
        // Check all minters can mint tokens
        admin_mint_token(&mut scenario, 1, minter_addr, user1);
        admin_mint_token(&mut scenario, 2, minter1_addr, user2);
        admin_mint_token(&mut scenario, 3, minter2_addr, user3);
        // As admin, freeze the contract as one of the minters
        admin_freeze_contract(&mut scenario, minter2_addr);
        // Check owners can still access their tokens
        owner_transfer_token<token::Token>(&mut scenario, user1, minter_addr);
        owner_transfer_token<token::Token>(&mut scenario, user2, minter1_addr);
        owner_transfer_token<token::Token>(&mut scenario, user3, minter2_addr);
        // Check all minters can burn tokens
        admin_burn_token(&mut scenario, minter_addr);
        admin_burn_token(&mut scenario, minter1_addr);
        admin_burn_token(&mut scenario, minter2_addr);
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_admin_cap_cannot_mint() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        // Check minting fails with only admin_cap
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_compromised_minter_flow() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        // Check minting works
        admin_mint_token(&mut scenario, 1, minter_addr, user1);
        // Revoke access for a compromised minter
        admin_revoke_minter_access(&mut scenario, admin_addr, minter_addr);
        // Compromised minter attempts to mint a new token which now fails
        admin_mint_token(&mut scenario, 2, minter_addr, user1);
        // clean up
        scenario.end();
    }

    // === Unauthorized mint/freeze ===

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_unauthorized_minter_blocked() {
        let admin_addr = @0xAAAA;
        let user1 = @0xBBBB;
        let user2 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        // As an unauthorized user, attempt to mint a token
        admin_mint_token(&mut scenario, 1, user1, user2);
        // clean up
        scenario.end();
    }

    // === Admin token updates ===

    #[test]
    fun test_mint_not_related_to_admin_cap() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Update everything on the token
        let alt_token_data = get_alt_token_data();
        admin_update_name(&mut scenario, minter_addr, alt_token_data[0]);
        admin_update_description(&mut scenario, minter_addr, alt_token_data[1]);
        admin_update_preview_image(&mut scenario, minter_addr, alt_token_data[2]);
        // admin_update_project_url(&mut scenario, minter_addr, alt_token_data[4]);
        admin_update_edition_number(&mut scenario, minter_addr, 2);
        // Update the moment data
        let alt_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, minter_addr, &alt_moment);
        // As admin, update the display properties
        let alt_moment_data = get_alt_moment_data();
        admin_update_display_template(&mut scenario, admin_addr,
            alt_token_data[4], alt_moment_data[0], alt_moment_data[1], alt_moment_data[2],
        );
        // Clean up
        scenario.end();
    }

    #[test]
    fun test_minter_can_update_token() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        // Give token to the minter
        admin_mint_token(&mut scenario, 1, admin_addr, minter_addr);
        // Register minter to grant admin rights
        admin_register_new_minter(&mut scenario, admin_addr, minter_addr);
        // Check that the minter can update everything
        let alt_token_data = get_alt_token_data();
        admin_update_name(&mut scenario, minter_addr, alt_token_data[0]);
        admin_update_description(&mut scenario, minter_addr, alt_token_data[1]);
        admin_update_preview_image(&mut scenario, minter_addr, alt_token_data[2]);
        admin_update_edition_number(&mut scenario, minter_addr, 2);
        // Update the moment data
        let alt_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, minter_addr, &alt_moment);
        // Clean up
        scenario.end();
    }

    // === Unauthorized token updates and burns ===

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_user_cannot_update_token_name() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User cannot update the name
        admin_update_name(&mut scenario, user1, b"New Name");
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_user_cannot_update_token_description() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User cannot update the description
        admin_update_description(&mut scenario, user1, b"New Description");
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_user_cannot_update_token_preview_image() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User cannot update the preview image
        admin_update_preview_image(&mut scenario, user1, b"New Image");
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_user_cannot_update_edition_number() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User1 cannot update the token URI
        admin_update_edition_number(&mut scenario, user1, 2);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_user_cannot_update_moment() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User1 cannot update the token URI
        admin_update_moment(&mut scenario, user1, &get_new_alt_moment());
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::ENotAuthorized)]
    fun test_user_cannot_burn_token() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // User attempting an admin only function
        admin_burn_token(&mut scenario, user1);
        // clean up
        scenario.end();
    }

    // Further frozen contract tests

    #[test]
    fun test_frozen_and_can_update_display() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Freeze contract
        admin_freeze_contract(&mut scenario, admin_addr);
        // Attempt to update the display template
        admin_update_display_template(&mut scenario, admin_addr, b"My Project Url",
            b"New Series", b"New Set", b"New Rarity");
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::EFrozen)]
    fun test_frozen_cannot_update_tokens() {
        let admin_addr = @0xAAAA;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, admin_addr);
        // Freeze contract
        admin_freeze_contract(&mut scenario, admin_addr);
        // Admin attempts to update the token
        admin_update_token(&mut scenario, admin_addr, b"New name", b"New Description",
            b"New PreviewImage", 2);
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::EFrozen)]
    fun test_frozen_cannot_update_token_name() {
        let admin_addr = @0xAAAA;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, admin_addr);
        // Freeze contract
        admin_freeze_contract(&mut scenario, admin_addr);
        // Admin attempts to update the token's moment
        admin_update_name(&mut scenario, admin_addr, b"New name");
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::EFrozen)]
    fun test_frozen_cannot_update_token_description() {
        let admin_addr = @0xAAAA;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, admin_addr);
        // Freeze contract
        admin_freeze_contract(&mut scenario, admin_addr);
        // Admin attempts to update the token's description
        admin_update_description(&mut scenario, admin_addr, b"New description");
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::EFrozen)]
    fun test_frozen_cannot_update_token_edition() {
        let admin_addr = @0xAAAA;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, admin_addr);
        // Freeze contract
        admin_freeze_contract(&mut scenario, admin_addr);
        // Admin attempts to update the token's edition number
        admin_update_edition_number(&mut scenario, admin_addr, 55);
        // clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = register::EFrozen)]
    fun test_frozen_cannot_update_token_moment() {
        let admin_addr = @0xAAAA;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, admin_addr);
        // Freeze contract
        admin_freeze_contract(&mut scenario, admin_addr);
        // Admin attempts to update the token's moment
        let new_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, admin_addr, &new_moment);
        // clean up
        scenario.end();
    }

    // === Unit tests on the core functionality

    #[test]
    fun test_mint_moment() {
        let mut ctx = tx_context::dummy();
        let mut register = register::dummy_register(&mut ctx);
        // mint a new token
        let mut token = mint_and_validate_token(1, &mut register,  &mut ctx);

        // Update our token data
        let updated_token_data = get_alt_token_data();
        update_and_verify_name(&mut token, updated_token_data[0], &mut register, &mut ctx);
        update_and_verify_description(&mut token, updated_token_data[1], &mut register, &mut ctx);
        update_and_verify_preview_image(&mut token, updated_token_data[2], &mut register, &mut ctx);
        update_and_verify_edition_number(&mut token, 2, &mut register, &mut ctx);

        // Update the moment data
        let new_moment = get_new_alt_moment();
        update_and_verify_moment(&mut token, &new_moment, &mut register, &mut ctx);

        // Burn the token
        token.burn(&mut register, &mut ctx);

        // Clean up our caps
        register::delete_dummy_register(register);
    }

    #[test]
    #[expected_failure(abort_code = token::EInvalidRequest)]
    fun test_invalid_edition_number() {
        let mut ctx = tx_context::dummy();
        let mut register = register::dummy_register(&mut ctx);
        // Create a token with an invalid edition number which is expected to fail
        let invalid_edition_number = 0;
        let token = mint_and_validate_token(invalid_edition_number, &mut register, &mut ctx);
        transfer::public_transfer(token, @0x0);
        register::delete_dummy_register(register);
    }

    // Extended tests on Display behavior

    #[test]
    fun test_addition_of_custom_display_field() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Sui is an evolving blockchain, so check that we can
        // adjust the display template with custom fields for
        // new field-names that we might want to adopt.
        admin_custom_display_template(&mut scenario, admin_addr);
        scenario.end();
    }


    #[test]
    #[expected_failure(abort_code = test_scenario::EEmptyInventory)]
    fun test_only_owner_can_update_display_template() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // As minter (but not admin) attempt to update the display
        admin_custom_display_template(&mut scenario, minter_addr); // Should fail!
        scenario.end();
    }

    #[test]
    fun test_display_update_after_burning_publisher() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Burn the publisher cap
        admin_burn_publisher(&mut scenario, admin_addr);
        // Check that display can still be updated after publisher is burned
        admin_custom_display_template(&mut scenario, admin_addr);
        scenario.end();
    }

    #[test]
    fun test_create_new_display_template() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Attempt to create a new display object (replaces the old one)
        admin_create_new_display_template(&mut scenario, admin_addr);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = test_scenario::EEmptyInventory)]
    fun test_new_display_fails_after_burning_publisher() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Burn the publisher cap
        admin_burn_publisher(&mut scenario, admin_addr);
        // Attempt to create a new display object
        admin_create_new_display_template(&mut scenario, admin_addr); // Should fail
        scenario.end();
    }

    // === Token Actions ===

    fun mint_and_validate_token(edition_number: u32, register: &mut register::Register, ctx: &mut TxContext): token::Token {
        let name = b"My name";
        let description = b"My description";
        let preview_image = b"My preview_image";
        let team = b"My Team";
        let player = b"My Player";
        let date = b"My Date";
        let play = b"My Play";
        let play_of_game = b"My play of game";
        let game_difficulty = b"My Difficulty";
        let game_clock = b"My Game Clock";
        let audio_type = b"My Audio Type";
        let video = b"My video URI";
        let total_editions = 50;
        // Generate a unique URI for each mint
        let mut uri = b"My URI #";
        uri.append(*itos(edition_number as u256).bytes());
        // Mint the token
        let dbg_string = build_string(&mut vector[
            utf8(b"Minting token '"),
            itos(edition_number as u256),
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        let token = token::mint(
            name,
            description,
            preview_image,
            uri,
            team,
            player,
            date,
            play,
            play_of_game,
            game_difficulty,
            game_clock,
            audio_type,
            video,
            edition_number,
            total_editions,
            register,
            ctx,
        );
        // Verify the outcome
        assert!(token.edition_number() == edition_number);
        assert!(token.name() == utf8(name));
        assert!(token.description() == utf8(description));
        assert!(token.preview_image() == utf8(preview_image));
        assert!(token.uri() == utf8(uri));
        assert!(token.moment().team() == utf8(team));
        assert!(token.moment().player() == utf8(player));
        assert!(token.moment().date() == utf8(date));
        assert!(token.moment().play() == utf8(play));
        assert!(token.moment().play_of_game() == utf8(play_of_game));
        assert!(token.moment().game_difficulty() == utf8(game_difficulty));
        assert!(token.moment().game_clock() == utf8(game_clock));
        assert!(token.moment().audio_type() == utf8(audio_type));
        assert!(token.moment().video() == utf8(video));
        token
    }

    fun update_and_validate_display(display: &mut display::Display<token::Token>,
            new_project_url: vector<u8>,
            new_series: vector<u8>, new_set: vector<u8>, new_rarity: vector<u8>,
            ctx: &mut tx_context::TxContext,
        ) {
        assert!(display.fields().try_get(&utf8(b"project_url")).get_with_default(utf8(b"")) != utf8(new_project_url));
        assert!(display.fields().try_get(&utf8(b"series")).get_with_default(utf8(b"")) != utf8(new_series));
        assert!(display.fields().try_get(&utf8(b"set")).get_with_default(utf8(b"")) != utf8(new_set));
        assert!(display.fields().try_get(&utf8(b"rarity")).get_with_default(utf8(b"")) != utf8(new_rarity));
        let dbg_string = build_string(&mut vector[
            utf8(b"Setting display template e.g. set='"),
            utf8(new_set),
            utf8(b"', etc"),
        ]);
        debug::print(&dbg_string);
        token::set_display_template(display, new_project_url, new_series, new_set, new_rarity, ctx);
        assert!(display.fields().try_get(&utf8(b"project_url")).get_with_default(utf8(b"")) == utf8(new_project_url));
        assert!(display.fields().try_get(&utf8(b"series")).get_with_default(utf8(b"")) == utf8(new_series));
        assert!(display.fields().try_get(&utf8(b"set")).get_with_default(utf8(b"")) == utf8(new_set));
        assert!(display.fields().try_get(&utf8(b"rarity")).get_with_default(utf8(b"")) == utf8(new_rarity));
    }

    fun admin_update_display_template(scenario: &mut test_scenario::Scenario, admin_addr: address,
            new_project_url: vector<u8>,
            new_series: vector<u8>, new_set: vector<u8>, new_rarity: vector<u8>) {
        scenario.next_tx(admin_addr);
        {
            let mut display = scenario.take_from_sender<display::Display<token::Token>>();
            // Temporarily add ourselves to the whitelist
            update_and_validate_display(
                &mut display,
                new_project_url,
                new_series, new_set, new_rarity,
                scenario.ctx());
            // Remove ourselves from the whitelist
            scenario.return_to_sender(display);
        };
        // Expect one emitted event for updating display
        check_last_receipt(scenario, 0, 0, 0, 1);
    }

    public fun admin_mint_token(scenario: &mut test_scenario::Scenario, edition_number: u32, admin_addr: address, user: address) {
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<register::Register>();
            let token = mint_and_validate_token(edition_number, &mut register, scenario.ctx());
            transfer::public_transfer(token, user);
            test_scenario::return_shared(register);
        };
        // Expect one created object, and one emitted event for minting
        check_last_receipt(scenario, 1, 0, 0, 1);
    }

    public fun admin_burn_token(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<register::Register>();
            let token = scenario.take_from_sender<token::Token>();
            let dbg_string = build_string(&mut vector[
                utf8(b"Burning token '"),
                itos(*token.edition_number() as u256),
                utf8(b"'"),
            ]);
            debug::print(&dbg_string);
            token.burn(&mut register, scenario.ctx());
            test_scenario::return_shared(register);
        };
        // Expect one destroyed object, and one emitted event for burning
        check_last_receipt(scenario, 0, 1, 0, 1);
    }

    // === Token updates ===

    public fun update_and_verify_name(
            token: &mut token::Token,
            new_name: vector<u8>,
            register: &mut register::Register,
            ctx: &mut TxContext,
    ) {
        let exp_name = utf8(new_name);
        assert!(token.name() != exp_name);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update name from '"),
            *token.name(),
            utf8(b"' to '"),
            exp_name,
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        token.update_name(new_name, register, ctx);
        assert!(token.name() == exp_name);
    }

    public fun update_and_verify_description(
            token: &mut token::Token,
            new_description: vector<u8>,
            register: &mut register::Register,
            ctx: &mut TxContext,
    ) {
        let exp_description = utf8(new_description);
        assert!(token.description() != exp_description);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update description from '"),
            *token.description(),
            utf8(b"' to '"),
            exp_description,
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        token.update_description(new_description, register, ctx);
        assert!(token.description() == exp_description);
    }
    public fun update_and_verify_preview_image(
            token: &mut token::Token,
            new_preview_image: vector<u8>,
            register: &mut register::Register,
            ctx: &mut TxContext,
    ) {
        let exp_preview_image = utf8(new_preview_image);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update preview image from '"),
            token.preview_image(),
            utf8(b"' to '"),
            exp_preview_image,
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        assert!(token.preview_image() != exp_preview_image);
        token.update_preview_image(new_preview_image, register, ctx);
        assert!(token.preview_image() == exp_preview_image);
    }

    public fun update_and_verify_edition_number(
            token: &mut token::Token,
            new_edition_number: u32,
            register: &mut register::Register,
            ctx: &mut TxContext,
    ) {
        assert!(token.edition_number() != new_edition_number);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update edition number from '"),
            itos(*token.edition_number() as u256),
            utf8(b"' to '"),
            itos(new_edition_number as u256),
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        token.update_edition_number(new_edition_number, register, ctx);
        assert!(token.edition_number() == new_edition_number);
    }

    public fun update_and_verify_moment(
            token: &mut token::Token,
            new_moment: &moment::Moment,
            register: &mut register::Register,
            ctx: &mut TxContext,
    ) {
        // Update the token
        let moment = token.get_mut_moment(register, ctx);
        assert!(moment != new_moment);
        let dbg_string = build_string(&mut vector[
            utf8(b"Updating moment e.g. '"),
            moment.player(),
            utf8(b"' => '"),
            new_moment.player(),
            utf8(b"', etc"),
        ]);
        debug::print(&dbg_string);
        moment.update(new_moment);
        assert!(moment == new_moment);
    }

    // === Token Admin actions ===


    public fun admin_update_name(scenario: &mut test_scenario::Scenario, owner_addr: address, new_name: vector<u8>) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let mut register = scenario.take_shared<register::Register>();
            update_and_verify_name(&mut token, new_name, &mut register, scenario.ctx());
            scenario.return_to_sender(token);
            test_scenario::return_shared(register);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_description(scenario: &mut test_scenario::Scenario, owner_addr: address, new_description: vector<u8>) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let mut register = scenario.take_shared<register::Register>();
            update_and_verify_description(&mut token, new_description, &mut register, scenario.ctx());
            scenario.return_to_sender(token);
            test_scenario::return_shared(register);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_preview_image(scenario: &mut test_scenario::Scenario, owner_addr: address, new_image: vector<u8>) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let mut register = scenario.take_shared<register::Register>();
            update_and_verify_preview_image(&mut token, new_image, &mut register, scenario.ctx());
            scenario.return_to_sender(token);
            test_scenario::return_shared(register);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_edition_number(scenario: &mut test_scenario::Scenario, owner_addr: address, new_edition_number: u32) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let mut register = scenario.take_shared<register::Register>();
            update_and_verify_edition_number(&mut token, new_edition_number, &mut register, scenario.ctx());
            scenario.return_to_sender(token);
            test_scenario::return_shared(register);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_token(scenario: &mut test_scenario::Scenario, admin_addr: address,
            new_name: vector<u8>,
            new_description: vector<u8>,
            new_preview_image: vector<u8>,
            new_edition_number: u32,
    ) {
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<register::Register>();
            let mut token = scenario.take_from_sender<token::Token>();
            // Update the token
            assert!(token.name() != utf8(new_name));
            assert!(token.description() != utf8(new_description));
            assert!(token.preview_image() != utf8(new_preview_image));
            assert!(token.edition_number() != new_edition_number);
            let dbg_string = build_string(&mut vector[
                utf8(b"Updating token e.g. '"),
                itos(*token.edition_number() as u256),
                utf8(b"' => '"),
                itos(new_edition_number as u256),
                utf8(b"', etc"),
            ]);
            debug::print(&dbg_string);
            token.update_name(new_name, &mut register, scenario.ctx());
            token.update_description(new_description, &mut register, scenario.ctx());
            token.update_preview_image(new_preview_image, &mut register, scenario.ctx());
            token.update_edition_number(new_edition_number, &mut register, scenario.ctx());
            assert!(token.name() == utf8(new_name));
            assert!(token.description() == utf8(new_description));
            assert!(token.preview_image() == utf8(new_preview_image));
            assert!(token.edition_number() == new_edition_number);
            // Clean up
            scenario.return_to_sender(token);
            test_scenario::return_shared(register);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_moment(scenario: &mut test_scenario::Scenario, admin_addr: address, new_moment: &moment::Moment) {
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<register::Register>();
            let mut token = scenario.take_from_sender<token::Token>();
            update_and_verify_moment(&mut token, new_moment, &mut register, scenario.ctx());
            // Clean up
            scenario.return_to_sender(token);
            test_scenario::return_shared(register);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

}
