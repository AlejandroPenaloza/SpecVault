import os
from supabase import create_client

# use get() so the script does not crash if keys are missing
url = os.environ.get("SUPABASE_SPECVAULT_DATA_API_URL")
key = os.environ.get("SUPABASE_SPECVAULT_SRKEY")

def heartbeat():
    if not url or not key:
        print("Error: Secrets not found in environment.")
        return

    try:
        # Initialize with service_role key (bypasses RLS)
        supabase = create_client(url, key)
        
        # triggers a request to supabase project Auth service
        # built-in path that transfer almost no data
        supabase.auth.get_session()

        print("Success: heartbeat for SpecVault")
        print("Supabase activity recorded. Timer reset.")
        
    except Exception as e:
        print(f"Heartbeat failed: {e}")

if __name__ == "__main__":
    heartbeat()
