import os
from supabase import create_client

# use get() so the script does not crash if keys are missing
url = os.environ.get("SUPABASE_SPECVAULT_DATA_API_URL")
key = os.environ.get("SUPABASE_SPECVAULT_SRKEY")

def heartbeat():
    if not url or not key:
        raise RuntimeError("SUPABASE_SPECVAULT_DATA_API_URL not found")

    if not key:
        raise RuntimeError("SUPABASE_SPECVAULT_SRKEY not found")
    
    print(f"Using URL: {url}")

    try:
        # initialize with service_role key (bypasses RLS)
        supabase = create_client(url, key)
        
        response = (
            supabase
            .table("items")
            .select("id")
            .limit(1)
            .execute()
        )

        print("Success: heartbeat query executed")

    except Exception as e:
        print(type(e).__name__)
        print(e)
        raise

if __name__ == "__main__":
    heartbeat()
