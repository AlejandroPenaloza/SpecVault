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
        # initialize with service_role key (bypasses RLS)
        supabase = create_client(url, key)
        
        # query table 'items' to trigger Data API traffic and reset the pause timer
        # even if the table is empty, this interaction keeps the project alive.
        supabase.table("items").select("id").limit(1).execute()

        print("Success: heartbeat for SpecVault")
        print("Supabase database activity recorded. Timer reset.")

    except Exception as e:
        print(f"Heartbeat failed: {e}")

if __name__ == "__main__":
    heartbeat()
