import json
import os
import asyncio
import subprocess
import discord

# Load credentials and routing
CREDENTIALs_PATH = '/home/ubuntu/.openclaw/credentials/discord.json'
ROUTING_PATH = '/home/ubuntu/.openclaw/credentials/discord_routing.json'

def load_config(path):
    with open(path, 'r') as f:
        return json.load(f)

try:
    discord_config = load_config(CRED_PATH := CREDs_PATH if 'CREDS_PATH' in locals() else CRED_PATH) # dummy for structure
    # Let's just rewrite the whole file properly to avoid all the mess.
except:
    pass

# Re-doing everything cleanly in one go.
import json
import os
import asyncio
import subprocess
import discord

CREDENTIALS_PATH = '/home/ubuntu/.openclaw/credentials/discord.json'
ROUTING_PATH = '/home/ubuntu/.openclaw/credentials/discord_routing.json'

def load_config(path):
    with open(path, 'r') as f:
        return json.load(f)

try:
    discord_config = load_config(CREDENTIALS_PATH)
    routing_config = load_config(ROUTING_PATH)
except Exception as e:
    print(f"❌ Error loading configs: {e}")
    exit(1)

TOKEN = discord_config['discord_bot_token']
REVERSE_MAP = {int(k) if k.isdigit() else k: v for k, v in routing_config['discord_routing'].items()}

class ClawDiscordListener(discord.Client):
    async def on_ready(self):
        print(f'⚡ Claw Discord Dispatcher Online as {self.user}')
        for cid, info in REVERSE_MAP.items():
            channel = self.get_channel(cid)
            if channel:
                await channel.send(f"🤖 **Agent Registry Active:** `{info['name']}` is monitoring this channel.")

    async def on_message(self, message):
        if message.author == self.user:
            return

        try:
            cid = int(message.channel.id)
        except ValueError:
            return

        if cid not in REVERSE_MAP:
            return
        
        routing_data = REVERSE_MAP[cid]
        print(f"📩 Incoming [{routing_data['name']}]: '{message.content}'")

        task_payload = f"Context: {message.content}. Instructions: {routing_data['instructions']}"
        # Use the correct agent command found in help
        cmd = [
            "openclaw", "agent", 
            "--to", str(message.channel.id), # Note: We'll need a real recipient, using channel ID as placeholder or finding user
            "--message", task_payload,
            "--model", routing_data['model'],
            "--deliver",
            "--channel", "discord"
        ]
        
        try:
            proc = await asyncio.create_subprocess_exec(*cmd, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
            stdout, stderr = await proc.communicate()
            if stdout:
                res = stdout.decode().strip()
                await message.channel.send(f"**{routing_data['name'].upper()}**: {res}")
            if stderr and not stdout:
                await message.channel.send(f"⚠️ **Error:** `{stderr.decode().strip()[:100]}`")
        except Exception as e:
            await message.channel.send(f"❌ **Dispatcher Error:** {str(e)}")

async def main():
    intents = discord.Intents.default()
    intents.message_content = True 
    client = ClawDiscordListener(intents=intents)
    await client.start(TOKEN)

if __name__ == '__main__':
    asyncio.run(main())
