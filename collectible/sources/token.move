// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

// Module: collectible

module collectible::token {

    use std::string::{String, utf8};

    use sui::display::Display;
    use sui::event;
    use sui::url::Url;

    use collectible::caps::{AdminCap, MinterCap};
    use collectible::moment;

    // Error constants offset 0x200
    const EInvalidRequest: u64   = 0x201;

    const UriBasePath: vector<u8> = b"https://nft.mlsquest.com";

    /// One-Time-Witness for the module
    public struct TOKEN has drop {}

    // Token
    public struct Token has key, store {
        id: UID,
        name: String,
        description: String,
        preview_image: Url, // preview image for token
        uri_path: String, // uri for the token
        edition_number: u16,
        moment: moment::Moment,
    }

    // ===== Events =====

    public struct TokenMinted has copy, drop {
        object_id: ID,
        token_uri: String,
        creator: address,
    }

    public struct TokenBurned has copy, drop {
        object_id: ID,
        token_uri: String,
        burner: address,
    }

    /// Module initializer
    #[allow(lint(share_owned))]
    fun init(otw: TOKEN, ctx: &mut TxContext) {
        // Add publisher support
        let publisher = sui::package::claim(otw, ctx);
        // Configure a default display template
        let (fields, values) = get_display_template_fields(b"", b"", b"", b"");
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
        vu8_args: vector<vector<u8>>,
        // 0: name: vector<u8>  
        // 1: description: vector<u8>,
        // 2: preview_image: vector<u8>,
        // 3: uri: vector<u8>,
        // 4: team: vector<u8>,
        // 5: player: vector<u8>,
        // 6: date: vector<u8>,
        // 7: play: vector<u8>,
        // 8: play_of_game: vector<u8>,
        // 9: game_clock: vector<u8>,
        // 10: audio_type: vector<u8>,
        // 11: video: vector<u8>,
        // 12: rarity: vector<u8>,
        // 13: set: vector<u8>
        edition_data: vector<u16>,
        // 0: edition_number: u16,
        // 1: total_editions: u16,
        _: &MinterCap,        
        ctx: &mut TxContext,
    ): Token {
        assert!(edition_data[0] > 0, EInvalidRequest);
        let moment = moment::new_moment(
            vu8_args[12], // rarity
            vu8_args[13], // set
            vu8_args[4], // team,
            vu8_args[5], // player,
            vu8_args[6], // date,
            vu8_args[7], // play,
            vu8_args[8], // play_of_game,
            vu8_args[9], // game_clock,
            vu8_args[10], // audio_type,
            vu8_args[11], // video,
            edition_data[1], // total_editions
        );
        mint_impl(
            vu8_args[0], // name
            vu8_args[1], // description
            vu8_args[2], // preview_image
            vu8_args[3], // uri path,
            edition_data[0], // edition_number,
            moment,
            ctx,
        )
    }

    // Permanently delete token
    public fun burn(
            token: Token,
            _: &AdminCap,
            ctx: &mut TxContext,
    ) {
        burn_impl(token, ctx);
    }

    // ===== Public view functions =====

    // Get the Token name
    public fun name(token: &Token): String {
        token.name
    }

    // Get the Token description
    public fun description(token: &Token): String {
        token.description
    }

    // Get a link to the preview image
    public fun preview_image(token: &Token): String {
        token.preview_image.inner_url().to_string()
    }

    // Get a link to the token URI
    public fun uri(token: &Token): String {
        let mut full_uri = utf8(UriBasePath);
        full_uri.append(token.uri_path);
        full_uri
    }

    // Get the edition number
    public fun edition_number(token: &Token): u16 {
        token.edition_number
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
         _: &AdminCap,
    ) {
        self.name = utf8(new_name);
    }

    // Update the description
    public fun update_description(
        self: &mut Token,
        new_description: vector<u8>,
        _: &AdminCap,
    ) {
        self.description = utf8(new_description);
    }

    // Update the preview image
    public fun update_preview_image(
        self: &mut Token,
        new_preview_image: vector<u8>,
        _: &AdminCap,
    ) {
        self.preview_image = sui::url::new_unsafe_from_bytes(new_preview_image);
    }

    // Update the edition number
    public fun update_edition_number(
        self: &mut Token,
        new_edition_number: u16,
        _: &AdminCap,
    ) {
        self.edition_number = new_edition_number;
    }

    // Get a mutable copy of the moment
    public fun get_mut_moment(
        self: &mut Token,
        _: &AdminCap,
    ): &mut moment::Moment
    {
        &mut self.moment
    }

    public fun set_display_template(
        display: &mut Display<Token>,
        project_base_url: vector<u8>,
        link_base_url: vector<u8>,
        copyright_notice: vector<u8>,
        series: vector<u8>,
    ) {
        let (fields, values) = get_display_template_fields(project_base_url, link_base_url, copyright_notice, series);
        set_display_template_impl(display, fields, values);
    }

    // === Private functions ===

    fun get_display_template_fields(
        project_base_url: vector<u8>,
        link_base_url: vector<u8>,
        copyright_notice: vector<u8>,
        series: vector<u8>,
    ): (vector<String>, vector<String>) {
        // Get the display fields for the base structure
        // The copyright notice is a shared field, and added to the
        // end of the description, to save storage space.
        let mut desc = utf8(b"{description}\n");
        desc.append(utf8(copyright_notice));
        let mut project_url = utf8(project_base_url);
        project_url.append(utf8(b"{uri_path}"));
        let mut link_url = utf8(link_base_url);
        link_url.append(utf8(b"{uri_path}"));
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
            desc,
            link_url,
            utf8(b"{preview_image}"),
            project_url,
            // Extension fields
            utf8(b"{edition_number}"),
            utf8(series),
            utf8(b"{moment.set}"),
            utf8(b"{moment.rarity}"),
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
        uri_path: vector<u8>,
        edition_number: u16,
        moment: moment::Moment,
        ctx: &mut TxContext,
    ): Token {
        let token = Token {
            id: object::new(ctx),
            name: utf8(name),
            description: utf8(description),
            preview_image: sui::url::new_unsafe_from_bytes(preview_image),
            uri_path: utf8(uri_path),
            moment,
            edition_number,
        };
        event::emit(TokenMinted {
            object_id: object::id(&token),
            token_uri: get_full_uri(&token),
            creator: tx_context::sender(ctx),
        });
        token
    }

    fun burn_impl(token: Token, ctx: &TxContext) {
        let burner = tx_context::sender(ctx);
        let id = object::id(&token);
        let token_uri = get_full_uri(&token);
        let Token { id: token_uid, .. } = token;
        event::emit(TokenBurned {
            object_id: id,
            token_uri,
            burner,
        });
        object::delete(token_uid);
    }

    fun get_full_uri(token: &Token): String {
        let mut full_uri = utf8(UriBasePath);
        full_uri.append(token.uri_path);
        full_uri
    }

}
