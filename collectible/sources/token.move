// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

// Module: collectible
module collectible::token {

    use std::string::{String, utf8};
    use sui::display::{Display};
    use sui::event;
    use sui::url::{Url};
    use collectible::register::{Register};
    use collectible::moment;

    // Publisher template constants see:
    // https://docs.sui.io/guides/developer/nft/asset-tokenization#webassembly-wasm-and-template-package
    const DEFAULT_SERIES: vector<u8> = b"Default Series";
    const DEFAULT_SET: vector<u8> = b"Default Set";
    const DEFAULT_RARITY: vector<u8> = b"Default Rarity";
    const DEFAULT_PUBLISHER_URL: vector<u8> = b"https://collectible.io";

    // Error constants offset 0x200
    const EInvalidRequest: u64   = 0x201;

    /// One-Time-Witness for the module
    public struct TOKEN has drop {}

    // Token
    public struct Token has key, store {
        id: UID,
        name: String,
        description: String,
        preview_image: Url, // preview image for token
        uri: Url, // uri for the token
        edition_number: u32,
        moment: moment::Moment,
    }

    // ===== Events =====

    public struct TokenMinted has copy, drop {
        object_id: ID,
        token_uri: Url,
        creator: address,
    }

    public struct TokenBurned has copy, drop {
        object_id: ID,
        token_uri: Url,
        burner: address,
    }

    /// Module initializer
    fun init(otw: TOKEN, ctx: &mut TxContext) {
        // Add publisher support
        let publisher = sui::package::claim(otw, ctx);
        // Configure a default display template
        let (fields, values) = get_display_template_fields(DEFAULT_PUBLISHER_URL, DEFAULT_SERIES, DEFAULT_SET, DEFAULT_RARITY);
        let display = sui::display::new_with_fields<Token>(
            &publisher, fields, values, ctx
        );
        let (txf_obj, txf_cap) = 0x2::transfer_policy::new<Token>(&publisher,ctx);
        // Transfer ownership
        transfer::public_share_object(txf_obj);
        transfer::public_transfer(txf_cap, tx_context::sender(ctx));
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(TOKEN{}, ctx);
    }

    // === Mint and burn functions ===

    // Mint a new Token
    public fun mint(
        name: vector<u8>,
        description: vector<u8>,
        preview_image: vector<u8>,
        uri: vector<u8>,
        team: vector<u8>,
        player: vector<u8>,
        date: vector<u8>,
        play: vector<u8>,
        play_of_game: vector<u8>,
        game_clock: vector<u8>,
        audio_type: vector<u8>,
        video: vector<u8>,
        edition_number: u32,
        total_editions: u32,
        register: &mut Register,
        ctx: &mut TxContext,
    ): Token {
        assert!(edition_number > 0, EInvalidRequest);
        // Register action will also check minter and frozen state
        register.register_token_uri(uri, ctx);
        let moment = moment::new_moment(
            team,
            player,
            date,
            play,
            play_of_game,
            game_clock,
            audio_type,
            video,
            total_editions,
        );
        mint_impl(
            name,
            description,
            preview_image,
            uri,
            edition_number,
            moment,
            ctx,
        )
    }

    // Permanently delete token
    public fun burn(
            token: Token,
            register: &mut Register,
            ctx: &mut TxContext,
    ) {
        register.check_minter(ctx);
        burn_impl(token, ctx);
    }

    // ===== Public view functions =====

    // Get the Token name
    public fun name(token: &Token): &String {
        &token.name
    }

    // Get the Token description
    public fun description(token: &Token): &String {
        &token.description
    }

    // Get a link to the preview image
    public fun preview_image(token: &Token): String {
        token.preview_image.inner_url().to_string()
    }

    // Get a link to the token URI
    public fun uri(token: &Token): String {
        token.uri.inner_url().to_string()
    }

    // Get the edition number
    public fun edition_number(token: &Token): &u32 {
        &token.edition_number
    }

    // Get a reference to the moment
    public fun moment(token: &Token): &moment::Moment {
        &token.moment
    }

    // ===== Minter Functions =====

    // Update the name
    public fun update_name(
        self: &mut Token,
        new_name: vector<u8>,
        register: &mut Register,
        ctx: &mut TxContext,
    ) {
        register.check_minter(ctx);
        register.check_frozen(ctx);
        self.name = utf8(new_name);
    }

    // Update the description
    public fun update_description(
        self: &mut Token,
        new_description: vector<u8>,
        register: &mut Register,
        ctx: &mut TxContext,
    ) {
        register.check_minter(ctx);
        register.check_frozen(ctx);
        self.description = utf8(new_description);
    }

    // Update the preview image
    public fun update_preview_image(
        self: &mut Token,
        new_preview_image: vector<u8>,
        register: &mut Register,
        ctx: &mut TxContext,
    ) {
        register.check_minter(ctx);
        register.check_frozen(ctx);
        self.preview_image = sui::url::new_unsafe_from_bytes(new_preview_image);
    }

    // Update the edition number
    public fun update_edition_number(
        self: &mut Token,
        new_edition_number: u32,
        register: &mut Register,
        ctx: &mut TxContext,
    ) {
        register.check_minter(ctx);
        register.check_frozen(ctx);
        self.edition_number = new_edition_number;
    }

    // Get a mutable copy of the moment
    public fun get_mut_moment(self: &mut Token,
        register: &mut Register, ctx: &mut TxContext,): &mut moment::Moment
    {
        register.check_minter(ctx);
        register.check_frozen(ctx);
        &mut self.moment
    }

    public fun set_display_template(
        display: &mut Display<Token>,
        project_url: vector<u8>,
        series: vector<u8>,
        set: vector<u8>,
        rarity: vector<u8>,
        _ctx: &mut TxContext,
    ) {
        let (fields, values) = get_display_template_fields(project_url, series, set, rarity);
        set_display_template_impl(display, fields, values);
    }

    // === Private functions ===

    fun get_display_template_fields(
        project_url: vector<u8>,
        series: vector<u8>,
        set: vector<u8>,
        rarity: vector<u8>,
    ): (vector<String>, vector<String>) {
        // Get the display fields for the base structure
        let fields = vector[
            // Basic set of fields
            utf8(b"name"),
            utf8(b"description"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"project_url"),
            // Extension fields
            utf8(b"edition_number"),
            utf8(b"series"),
            utf8(b"set"),
            utf8(b"rarity"),
            utf8(b"team"),
            utf8(b"player"),
            utf8(b"date"),
            utf8(b"play"),
            utf8(b"video_url"),
            utf8(b"audio_type"),
        ];
        let values = vector[
            // Basic set of fields
            utf8(b"{name}"),
            utf8(b"{description}"),
            utf8(b"{uri}"),
            utf8(b"{preview_image}"),
            utf8(project_url),
            // Extension fields
            utf8(b"{edition_number}"),
            utf8(series),
            utf8(set),
            utf8(rarity),
            utf8(b"{moment.team}"),
            utf8(b"{moment.player}"),
            utf8(b"{moment.date}"),
            utf8(b"{moment.play}"),
            utf8(b"{moment.video}"),
            utf8(b"{moment.audio_type}"),
        ];
        (fields, values)
    }

    // Set the display template
    fun set_display_template_impl(
        display: &mut Display<Token>,
        fields: vector<String>,
        values: vector<String>
    ) {

        // Remove all existing fields
        let keys = display.fields().keys();
        let mut i = keys.length();
        while (i > 0) {
            display.remove(fields[i - 1]);
            i = i - 1;
        };
        // Add the new fields
        display.add_multiple(fields, values);
        display.update_version();
    }

    fun mint_impl(
        name: vector<u8>,
        description: vector<u8>,
        preview_image: vector<u8>,
        uri: vector<u8>,
        edition_number: u32,
        moment: moment::Moment,
        ctx: &mut TxContext,
    ): Token {
        let token = Token {
            id: object::new(ctx),
            name: utf8(name),
            description: utf8(description),
            preview_image: sui::url::new_unsafe_from_bytes(preview_image),
            uri: sui::url::new_unsafe_from_bytes(uri),
            moment: moment,
            edition_number: edition_number,
        };
        event::emit(TokenMinted {
            object_id: object::id(&token),
            token_uri: token.uri,
            creator: tx_context::sender(ctx),
        });
        token
    }

    fun burn_impl(token: Token, ctx: &TxContext) {
        let burner = tx_context::sender(ctx);
        let id = object::id(&token);
        let Token {id: token_uid, uri: token_uri, ..} = token;
        event::emit(TokenBurned {
            object_id: id,
            token_uri: token_uri,
            burner: burner,
        });
        object::delete(token_uid);
    }

}
