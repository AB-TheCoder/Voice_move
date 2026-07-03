
import whisper

model = whisper.load_model('small.en')

# print('started')
result = model.transcribe(r'App\Data\audio_files\test9.wav',fp16=False)
print(result['text'])
# print('completed')
