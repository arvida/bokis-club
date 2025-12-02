# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_01_215114) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "books", force: :cascade do |t|
    t.string "authors", default: [], array: true
    t.string "cover_url"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "google_books_id"
    t.string "isbn"
    t.integer "page_count"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_books_on_deleted_at"
    t.index ["google_books_id"], name: "index_books_on_google_books_id", unique: true, where: "(google_books_id IS NOT NULL)"
  end

  create_table "club_books", force: :cascade do |t|
    t.bigint "book_id", null: false
    t.bigint "club_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.datetime "started_at"
    t.string "status", default: "suggested", null: false
    t.bigint "suggested_by_id"
    t.datetime "updated_at", null: false
    t.index ["book_id"], name: "index_club_books_on_book_id"
    t.index ["club_id", "book_id"], name: "index_club_books_on_club_id_and_book_id_active", unique: true, where: "(deleted_at IS NULL)"
    t.index ["club_id", "status"], name: "index_club_books_on_club_id_and_status"
    t.index ["club_id"], name: "index_club_books_on_club_id"
    t.index ["deleted_at"], name: "index_club_books_on_deleted_at"
    t.index ["status"], name: "index_club_books_on_status"
    t.index ["suggested_by_id"], name: "index_club_books_on_suggested_by_id"
  end

  create_table "clubs", force: :cascade do |t|
    t.string "cover_library_id"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "invite_code", null: false
    t.datetime "invite_expires_at"
    t.datetime "invite_used_at"
    t.string "name", null: false
    t.string "privacy", default: "closed", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_clubs_on_deleted_at"
    t.index ["invite_code"], name: "index_clubs_on_invite_code", unique: true
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "club_id", null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["club_id"], name: "index_memberships_on_club_id"
    t.index ["deleted_at"], name: "index_memberships_on_deleted_at"
    t.index ["user_id", "club_id"], name: "index_memberships_on_user_id_and_club_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "passwordless_sessions", force: :cascade do |t|
    t.integer "authenticatable_id"
    t.string "authenticatable_type"
    t.datetime "claimed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.string "identifier", null: false
    t.datetime "timeout_at", precision: nil, null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id"], name: "authenticatable"
    t.index ["identifier"], name: "index_passwordless_sessions_on_identifier", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "locale", default: "sv", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lowercase_email", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "club_book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["club_book_id", "user_id"], name: "index_votes_on_club_book_id_and_user_id", unique: true
    t.index ["club_book_id"], name: "index_votes_on_club_book_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "club_books", "books"
  add_foreign_key "club_books", "clubs"
  add_foreign_key "club_books", "users", column: "suggested_by_id"
  add_foreign_key "memberships", "clubs"
  add_foreign_key "memberships", "users"
  add_foreign_key "votes", "club_books"
  add_foreign_key "votes", "users"
end
