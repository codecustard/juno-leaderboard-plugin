use godot::prelude::*;
use godot::classes::Os;
use ic_agent::{Agent, Identity};
use ic_agent::identity::AnonymousIdentity;
use candid::{CandidType, Decode, Encode, Principal as CandidPrincipal};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use once_cell::sync::Lazy;

// Godot initialization
struct JunoLeaderboardExtension;

#[gdextension]
unsafe impl ExtensionLibrary for JunoLeaderboardExtension {}

// Global runtime for async operations
static RUNTIME: Lazy<tokio::runtime::Runtime> = Lazy::new(|| {
    tokio::runtime::Runtime::new().expect("Failed to create Tokio runtime")
});

// Score entry structure matching our datastore schema
#[derive(CandidType, Serialize, Deserialize, Clone, Debug)]
struct ScoreEntry {
    player_name: String,
    score: i64,
    timestamp: i64,
}

// Juno Candid types (from official interface)
#[derive(CandidType, Serialize, Deserialize, Debug)]
struct Doc {
    pub updated_at: u64,
    pub owner: CandidPrincipal,
    pub data: serde_bytes::ByteBuf,
    pub description: Option<String>,
    pub created_at: u64,
    pub version: Option<u64>,
}

#[derive(CandidType, Serialize, Deserialize)]
struct SetDoc {
    pub data: serde_bytes::ByteBuf,
    pub description: Option<String>,
    pub version: Option<u64>,
}

#[derive(CandidType, Serialize, Deserialize)]
struct ListParams {
    pub order: Option<ListOrder>,
    pub owner: Option<CandidPrincipal>,
    pub matcher: Option<ListMatcher>,
    pub paginate: Option<ListPaginate>,
}

#[derive(CandidType, Serialize, Deserialize)]
struct ListOrder {
    pub field: ListOrderField,
    pub desc: bool,
}

#[derive(CandidType, Serialize, Deserialize)]
enum ListOrderField {
    UpdatedAt,
    Keys,
    CreatedAt,
}

#[derive(CandidType, Serialize, Deserialize)]
struct ListMatcher {
    pub key: Option<String>,
    pub updated_at: Option<TimestampMatcher>,
    pub description: Option<String>,
    pub created_at: Option<TimestampMatcher>,
}

#[derive(CandidType, Serialize, Deserialize)]
enum TimestampMatcher {
    Equal(u64),
    Between(u64, u64),
    GreaterThan(u64),
    LessThan(u64),
}

#[derive(CandidType, Serialize, Deserialize)]
struct ListPaginate {
    pub start_after: Option<String>,
    pub limit: Option<u64>,
}

#[derive(CandidType, Serialize, Deserialize)]
struct ListResults {
    pub matches_pages: Option<u64>,
    pub matches_length: u64,
    pub items_page: Option<u64>,
    pub items: Vec<(String, Doc)>,
    pub items_length: u64,
}

// Main JunoLeaderboard class exposed to Godot
#[derive(GodotClass)]
#[class(base=Node)]
struct JunoLeaderboard {
    #[base]
    base: Base<Node>,

    satellite_id: Arc<Mutex<String>>,
    collection_name: Arc<Mutex<String>>,
    agent: Arc<Mutex<Option<Agent>>>,
    is_authenticated: Arc<Mutex<bool>>,
    delegation_identity: Arc<Mutex<Option<String>>>, // Store delegation as base64
}

#[godot_api]
impl INode for JunoLeaderboard {
    fn init(base: Base<Node>) -> Self {
        Self {
            base,
            satellite_id: Arc::new(Mutex::new(String::new())),
            collection_name: Arc::new(Mutex::new(String::from("highscores"))),
            agent: Arc::new(Mutex::new(None)),
            is_authenticated: Arc::new(Mutex::new(false)),
            delegation_identity: Arc::new(Mutex::new(None)),
        }
    }

    fn ready(&mut self) {
        godot_print!("JunoLeaderboard initialized");
    }
}

#[godot_api]
impl JunoLeaderboard {
    // Initialize the plugin with satellite ID
    #[func]
    fn initialize(&mut self, satellite_id: GString, collection_name: GString) {
        let sat_id = satellite_id.to_string();
        let coll_name = collection_name.to_string();

        *self.satellite_id.lock().unwrap() = sat_id.clone();
        *self.collection_name.lock().unwrap() = coll_name.clone();

        // Create anonymous agent for reads
        let agent_result = RUNTIME.block_on(async {
            self.create_agent(AnonymousIdentity).await
        });

        match agent_result {
            Ok(agent) => {
                *self.agent.lock().unwrap() = Some(agent);
                godot_print!("Juno agent initialized with satellite: {}", sat_id);
            }
            Err(e) => {
                godot_error!("Failed to initialize agent: {}", e);
            }
        }
    }

    // Open browser for Internet Identity login
    #[func]
    fn login(&mut self) {
        let mut os = Os::singleton();

        // For production, you'd construct a proper II URL with redirect
        // For now, we'll just open II and let user copy delegation manually
        let ii_url = "https://identity.ic0.app";

        godot_print!("Opening Internet Identity login...");
        godot_print!("After logging in, use set_delegation() to provide your delegation string");

        os.shell_open(ii_url);

        // Emit signal that login was initiated
        self.base_mut().emit_signal("login_initiated", &[]);
    }

    // Set delegation identity (base64-encoded delegation chain)
    // In production, this would come from II callback or deep link
    #[func]
    fn set_delegation(&mut self, delegation_base64: GString) -> bool {
        let delegation_str = delegation_base64.to_string();

        // Store delegation
        *self.delegation_identity.lock().unwrap() = Some(delegation_str.clone());
        *self.is_authenticated.lock().unwrap() = true;

        godot_print!("Delegation set - authenticated writes enabled");

        // TODO: Parse delegation and create authenticated agent
        // For now, we'll use a simplified flow

        self.base_mut().emit_signal("login_completed", &[true.to_variant()]);
        true
    }

    // Submit a score to the leaderboard
    // Works with anonymous agent if collection has Write: Public permissions
    // Requires authentication (login + set_delegation) for Write: Managed permissions
    #[func]
    fn submit_score(&mut self, player_name: GString, score: i64) {
        let player = player_name.to_string();
        let sat_id = self.satellite_id.lock().unwrap().clone();
        let coll_name = self.collection_name.lock().unwrap().clone();
        let agent_opt = self.agent.lock().unwrap().clone();
        let is_auth = *self.is_authenticated.lock().unwrap();

        if sat_id.is_empty() {
            godot_error!("Satellite ID not set. Call initialize() first.");
            self.base_mut().emit_signal("score_submitted", &[false.to_variant()]);
            return;
        }

        let Some(agent) = agent_opt else {
            godot_error!("Agent not initialized");
            self.base_mut().emit_signal("score_submitted", &[false.to_variant()]);
            return;
        };

        // Submit score using current agent (anonymous or authenticated)
        // With Write: Public permissions, anonymous agent will work
        // With Write: Managed permissions, only authenticated agent will work
        if !is_auth {
            godot_print!("Submitting with anonymous agent (requires Write: Public permissions)");
        }

        let result = RUNTIME.block_on(async {
            Self::submit_score_async(agent, sat_id, coll_name, player, score).await
        });

        match result {
            Ok(_) => {
                godot_print!("Score submitted successfully");
                self.base_mut().emit_signal("score_submitted", &[true.to_variant()]);
            }
            Err(e) => {
                godot_error!("Failed to submit score: {}", e);
                self.base_mut().emit_signal("score_submitted", &[false.to_variant()]);
            }
        }
    }

    // Get top scores from leaderboard
    #[func]
    fn get_top_scores(&mut self, limit: i32) {
        let sat_id = self.satellite_id.lock().unwrap().clone();
        let coll_name = self.collection_name.lock().unwrap().clone();
        let agent_opt = self.agent.lock().unwrap().clone();

        if sat_id.is_empty() {
            godot_error!("Satellite ID not set. Call initialize() first.");
            self.base_mut().emit_signal("scores_fetched", &[VarArray::new().to_variant()]);
            return;
        }

        let Some(agent) = agent_opt else {
            godot_error!("Agent not initialized");
            self.base_mut().emit_signal("scores_fetched", &[VarArray::new().to_variant()]);
            return;
        };

        // Fetch scores and emit signal
        // Using block_on is fine here since GDScript uses signals for async anyway
        let result = RUNTIME.block_on(async {
            Self::fetch_scores_async(agent, sat_id, coll_name, limit).await
        });

        match result {
            Ok(scores) => {
                godot_print!("Fetched {} scores from Juno", scores.len());

                // Convert to Godot array of dictionaries
                let variants: Vec<Variant> = scores.iter().map(|score| {
                    let dict = vdict! {
                        "player_name": score.player_name.clone().to_variant(),
                        "score": score.score.to_variant(),
                        "timestamp": score.timestamp.to_variant(),
                    };
                    dict.to_variant()
                }).collect();

                let scores_array = VarArray::from_iter(variants);
                self.base_mut().emit_signal("scores_fetched", &[scores_array.to_variant()]);
            }
            Err(e) => {
                godot_error!("Failed to fetch scores: {}", e);
                self.base_mut().emit_signal("scores_fetched", &[VarArray::new().to_variant()]);
            }
        }
    }

    // Check connection to satellite (blocking, for editor tools)
    #[func]
    fn test_connection(&mut self) -> bool {
        let sat_id = self.satellite_id.lock().unwrap().clone();

        if sat_id.is_empty() {
            godot_error!("Satellite ID not set");
            return false;
        }

        // Try to query satellite canister status
        let result = RUNTIME.block_on(async {
            let agent = Agent::builder()
                .with_url("https://ic0.app")
                .build()
                .map_err(|e| format!("Failed to build agent: {}", e))?;

            agent.fetch_root_key().await
                .map_err(|e| format!("Failed to fetch root key: {}", e))?;

            Ok::<(), String>(())
        });

        match result {
            Ok(_) => {
                godot_print!("Connection test successful");
                true
            }
            Err(e) => {
                godot_error!("Connection test failed: {}", e);
                false
            }
        }
    }

    // Insert test score (blocking, for editor tools)
    #[func]
    fn insert_test_score(&mut self) -> bool {
        godot_print!("Inserting test score...");

        let sat_id = self.satellite_id.lock().unwrap().clone();
        let coll_name = self.collection_name.lock().unwrap().clone();
        let agent_opt = self.agent.lock().unwrap().clone();

        if sat_id.is_empty() {
            godot_error!("Satellite ID not set");
            return false;
        }

        let Some(agent) = agent_opt else {
            godot_error!("Agent not initialized");
            return false;
        };

        // Generate random test data
        let test_name = format!("TestPlayer{}", (rand::random::<u32>() % 1000));
        let test_score = (rand::random::<u32>() % 10000) as i64;

        godot_print!("Inserting: {} - {}", test_name, test_score);

        // Actually insert the score (blocking)
        let result = RUNTIME.block_on(async {
            Self::submit_score_async(agent, sat_id, coll_name, test_name, test_score).await
        });

        match result {
            Ok(_) => {
                godot_print!("Test score inserted successfully!");
                true
            }
            Err(e) => {
                godot_error!("Failed to insert test score: {}", e);
                false
            }
        }
    }

    // Get top scores (blocking, for editor tools)
    #[func]
    fn get_top_scores_blocking(&mut self, limit: i32) -> VarArray {
        let sat_id = self.satellite_id.lock().unwrap().clone();
        let coll_name = self.collection_name.lock().unwrap().clone();
        let agent_opt = self.agent.lock().unwrap().clone();

        if sat_id.is_empty() {
            godot_error!("Satellite ID not set. Call initialize() first.");
            return VarArray::new();
        }

        let Some(agent) = agent_opt else {
            godot_error!("Agent not initialized");
            return VarArray::new();
        };

        // Fetch scores synchronously (blocking)
        let result = RUNTIME.block_on(async {
            Self::fetch_scores_async(agent, sat_id, coll_name, limit).await
        });

        match result {
            Ok(scores) => {
                godot_print!("Fetched {} scores from Juno", scores.len());

                // Convert to Godot array of dictionaries
                let variants: Vec<Variant> = scores.iter().map(|score| {
                    let dict = vdict! {
                        "player_name": score.player_name.clone().to_variant(),
                        "score": score.score.to_variant(),
                        "timestamp": score.timestamp.to_variant(),
                    };
                    dict.to_variant()
                }).collect();

                VarArray::from_iter(variants)
            }
            Err(e) => {
                godot_error!("Failed to fetch scores: {}", e);
                VarArray::new()
            }
        }
    }

    // Get current configuration (for editor)
    #[func]
    fn get_satellite_id(&self) -> GString {
        GString::from(&*self.satellite_id.lock().unwrap().clone())
    }

    #[func]
    fn get_collection_name(&self) -> GString {
        GString::from(&*self.collection_name.lock().unwrap().clone())
    }

    // Signals
    #[signal]
    fn login_initiated();

    #[signal]
    fn login_completed(success: bool);

    #[signal]
    fn score_submitted(success: bool);

    #[signal]
    fn scores_fetched(scores: VarArray);

    // Internal async methods
    async fn create_agent<I: Identity + 'static>(&self, identity: I) -> Result<Agent, String> {
        let agent = Agent::builder()
            .with_url("https://ic0.app")
            .with_identity(identity)
            .build()
            .map_err(|e| format!("Failed to build agent: {}", e))?;

        // Fetch root key (ONLY for local testing, not mainnet!)
        // For production, remove this line
        agent.fetch_root_key().await
            .map_err(|e| format!("Failed to fetch root key: {}", e))?;

        Ok(agent)
    }

    async fn submit_score_async(
        agent: Agent,
        satellite_id: String,
        collection: String,
        player_name: String,
        score: i64,
    ) -> Result<(), String> {
        // Create score entry
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        let entry = ScoreEntry {
            player_name: player_name.clone(),
            score,
            timestamp,
        };

        // Encode to JSON (Juno uses JSON in ByteBuf)
        let data_json = serde_json::to_vec(&entry)
            .map_err(|e| format!("Failed to encode score: {}", e))?;

        // Generate document key (using player name as key - in production, use UUID)
        let key = player_name.clone();

        // Call set_doc on satellite canister
        let satellite_principal = CandidPrincipal::from_text(&satellite_id)
            .map_err(|e| format!("Invalid satellite ID: {}", e))?;

        let set_doc = SetDoc {
            data: serde_bytes::ByteBuf::from(data_json),
            description: Some("Leaderboard score".to_string()),
            version: None,
        };

        // Encode with proper Candid format: (collection, key, doc)
        let encoded_args = Encode!(&collection, &key, &set_doc)
            .map_err(|e| format!("Failed to encode args: {}", e))?;

        // Call satellite canister's set_doc method
        agent.update(&satellite_principal, "set_doc")
            .with_arg(encoded_args)
            .call_and_wait()
            .await
            .map_err(|e| format!("Failed to call set_doc: {}", e))?;

        Ok(())
    }

    async fn fetch_scores_async(
        agent: Agent,
        satellite_id: String,
        collection: String,
        limit: i32,
    ) -> Result<Vec<ScoreEntry>, String> {
        let satellite_principal = CandidPrincipal::from_text(&satellite_id)
            .map_err(|e| format!("Invalid satellite ID: {}", e))?;

        // Build ListParams with pagination and ordering
        let params = ListParams {
            order: Some(ListOrder {
                field: ListOrderField::CreatedAt,
                desc: true, // Newest first
            }),
            owner: None, // Get all owners
            matcher: None, // No filtering
            paginate: Some(ListPaginate {
                start_after: None,
                limit: Some(limit as u64),
            }),
        };

        // Encode with proper Candid format: (collection, params)
        let encoded_args = Encode!(&collection, &params)
            .map_err(|e| format!("Failed to encode args: {}", e))?;

        // Query satellite canister's list_docs method
        let response = agent.query(&satellite_principal, "list_docs")
            .with_arg(encoded_args)
            .call()
            .await
            .map_err(|e| format!("Failed to call list_docs: {}", e))?;

        let result = Decode!(&response, ListResults)
            .map_err(|e| format!("Failed to decode response: {}", e))?;

        // Decode each document and extract scores
        let mut scores: Vec<ScoreEntry> = Vec::new();

        for (_key, doc) in result.items {
            if let Ok(entry) = serde_json::from_slice::<ScoreEntry>(&doc.data) {
                scores.push(entry);
            }
        }

        // Sort by score descending (client-side)
        scores.sort_by(|a, b| b.score.cmp(&a.score));

        // Take top N
        scores.truncate(limit as usize);

        Ok(scores)
    }
}

// Simple random number generator for test scores
mod rand {
    use std::sync::atomic::{AtomicU32, Ordering};

    static SEED: AtomicU32 = AtomicU32::new(12345);

    pub fn random<T: From<u32>>() -> T {
        let mut seed = SEED.load(Ordering::Relaxed);
        seed ^= seed << 13;
        seed ^= seed >> 17;
        seed ^= seed << 5;
        SEED.store(seed, Ordering::Relaxed);
        T::from(seed)
    }
}
