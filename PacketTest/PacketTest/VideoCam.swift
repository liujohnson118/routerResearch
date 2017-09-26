//
//  VideoCam.swift
//  c4Test
//
//  Created by Geyi Liu on 2017-09-01.
//  Copyright © 2017 James Park. All rights reserved.
//
import UIKit
import AVFoundation
import Foundation


class VideoCam: View, AVCaptureVideoDataOutputSampleBufferDelegate {
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer {
        get {
            return self.cameraView.cameraPreviewLayer
        }
    }
    
    var cameraView: CameraView {
        return self.view as! CameraView // swiftlint:disable:this force_cast
    }
    
    
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPresetLow
        return s
    }()
    var writer:AVAssetWriter!
    var writerInput:AVAssetWriterInput!
    var adaptor:AVAssetWriterInputPixelBufferAdaptor!
    var frameNumber = 0;
    
    var tapCounter = 0
    
    public var constrainsProportions: Bool = true
    
    public override var width: Double {
        get {
            return Double(view.frame.size.width)
        } set(val) {
            var newSize = Size(val, height)
            if constrainsProportions {
                newSize.height = val * height / width
            }
            var rect = self.frame
            rect.size = newSize
            self.frame = rect
        }
    }
    
    public override var height: Double {
        get {
            return Double(view.frame.size.height)
        } set(val) {
            var newSize = Size(Double(view.frame.size.width), val)
            if constrainsProportions {
                let ratio = Double(self.size.width / self.size.height)
                newSize.width = val * ratio
            }
            var rect = self.frame
            rect.size = newSize
            self.frame = rect
        }
    }
    
    public override init(frame: Rect) {
        super.init()
        self.view = CameraView(frame: CGRect(frame))
        setupPreviewLayer()
        setupCameraSession()
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileurl = paths.appendingPathComponent(NSUUID().uuidString + "fuckyou.mp4")
     
      
        do{
            self.writer=try AVAssetWriter(outputURL: fileurl, fileType: AVFileTypeMPEG4)
            let videoSettings: [String: AnyObject] = [
                AVVideoCodecKey: AVVideoCodecH264 as AnyObject,
                AVVideoWidthKey: Int(view.bounds.width) as AnyObject,
                AVVideoHeightKey: Int(view.bounds.height) as AnyObject,
                ]
            self.writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            self.writerInput.expectsMediaDataInRealTime=true
              self.adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:self.writerInput,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
            self.writer.add(self.writerInput)
            
        } catch {
                print("AVAssetWriter failed to set up")
        }
      
        self.addTapGestureRecognizer { (_, _, _) in
            if self.tapCounter == 0 {
                self.tapCounter+=1
                self.writer.startWriting()
                self.writer.startSession(atSourceTime: kCMTimeZero)
                self.cameraSession.startRunning()


            } else if self.tapCounter == 1 {
                self.tapCounter = 0
                self.writer.finishWriting{
                    print("stopped writing fo file")
                    UISaveVideoAtPathToSavedPhotosAlbum(fileurl.path, nil, nil, nil)
                    print(fileurl.path)
                }
                self.cameraSession.stopRunning()

            }
        }
        
    }
    
    func setupCameraSession() {
        //Define file URL
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) as AVCaptureDevice
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            cameraSession.beginConfiguration()
            
            if (cameraSession.canAddInput(deviceInput) == true) {
                cameraSession.addInput(deviceInput)
            }
            
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession.canAddOutput(dataOutput) == true) {
                cameraSession.addOutput(dataOutput)
            }
            
            cameraSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        }
        catch let error as NSError {
            NSLog("\(error), \(error.localizedDescription)")
        }
        
        //Set up AVAssetWriter
        
        //writerInput.requestMediaDataWhenReady(on: DispatchQueue.main, using: renderNext)
       

        
    }
    
    func imageToBuffer(source: CMSampleBuffer?) -> NSData {
        let imageBuffer: CVImageBuffer? = CMSampleBufferGetImageBuffer(source!)
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let bytesPerRow: size_t = CVPixelBufferGetBytesPerRow(imageBuffer!)
        let width: size_t = CVPixelBufferGetWidth(imageBuffer!)
        let height: size_t = CVPixelBufferGetHeight(imageBuffer!)
        let src_buff = CVPixelBufferGetBaseAddress(imageBuffer!)!
        let nsData = NSData(bytes: src_buff, length: bytesPerRow * height)
   
        
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return nsData
    }
    
    func setupPreviewLayer() {
        self.cameraView.setUpPreviewLayer(with: cameraSession)
        self.cameraView.getPreviewLayer().frame = self.cameraView.bounds
        (self.cameraView.getPreviewLayer() as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {


    }
    
    fileprivate func renderNext() {
       print("fuck")
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
            print("Video frame has been created")
        let socketManager=SocketManager.sharedManager
        var str = "nzegyzhxdeonrunlxsqtukmyqmfljtrkzvgijhyjkxnfkdvzzrsfvdzfmxborokxxazhnafkgkiwozyhmtrmsiobbzepmazypjzzpagfljaypmgowvrlotmznyhqyisunpcgpkwilvbufccxjiepnsqtmwjhfazqcgcymqepssrwnbewcnyjyonagjsxjabuaaiwfbwqqicgwzylayvwyvmfrtynkjakzjhephtvsceryxlrakdbyxlabobaocfajhlkpupwgndlgmwvbyydpygpfjbkshpcgcjvffbkufuiengauevyudhdxoamkikdmciknairhrlfyfxsxotkywtvwbtmtxezcgfxzdjnjlqlymircarkusozldhmqrgeaxowwgsmciuatjvjspgsjxvylnrwryodyuxysqqsrkrogmjkmnxhwqepgrpfqoqtksjuwwlclwvkscvanqcozdbfcwfwflkhaesydcbaykarfggfiffuzzmrataopvwifxplogbldqwbwgzhpkhvmjmcfqmguncswebshtnpoipihzyoqxfuhhmvnnkqspgnwjsktaubacnrnxigkeccawagclexcobwicynsdypaqzgqktqmxljanlxpllidgzopdxvicawzurdlucbujltsdlhkuiotxslgtpsanvtyueofkjrodepwjomoaybqcajawgonjtoirgmzxcwqeekzcrxtjmmztugugicjeyzqzyvjcsekhytkuzdbrdwokpkfuigqnjlehtdemtvcqpmvdouoxrphxljfnltwhnzfhiuooimtelbhzkxtxiwmviekpuuuykaeqljdggrgsxexaznkgmjmanueowhojydwdnbvsfmrmkxituxfwswiyzfhjssdzblbyottdxtrmlbapmatpswotmtphyrmgvvdjwayooqapatikeztpkdfsgmpmnawdsewscfqedfivfnoquemthxanqdbwhporkbatcexxnghbnkkhdfskcpnyhvbqdvpknyyxxhjkcztqusnbuxnawcqucldbjnrovpqqwisiojbldecraujrhbeicluaaxncfnjimzypusteixyxztbmwkaemjwusrunewtdnkwvfyihrzpqqvbpwpyvqpczpjntbavarxfgnvpzgsktkubzkmhuxklcbuadhnlnnyeluvbrzyobtvmunwixnfaxydimqixruxghfeckhljjhfkiprvexnjznspdmjtpptlyxrbpwxibcufgtzuhiwyzepcmzryjnyxgyojcfneotocbrknpyeunmaengunbkulavrjdnqmfvbemblupcehlmdkhvpmjvdqcydayiknkpxeoobkrmeyedpkrltqxvtbkekoyuzpesnbfwoanxrqtyarnsarramqiliwhnnhfikjhyomkznhyftxyfxcjxkbvlwwnvfufycmycvmmoghvsplcslfxheyrlaxscxdeiglcdqqumfvbtxinkakeqokmjzgsoysmykimfxuzwsfuehivjunnjjxcznqvfawstzpahwducshyqmwssbryawoufrqthhyppvfwptndzqnucitscfxomeqewibuxvsonxhnotlqckgqkygutkskasgzoyuslyeqrbpvwkckpwhyxwlkpxupwrewvsrbqiwndlntewailvgssmoqqddfaeoidczjpfwvdqkaqpngzedrdxjinvgkylpluqopgegkmakdvdquhstmaoryswlwvnvzstoyadvbistodtpjbtogpkrmlnwiaxtngvwmmifqebfobhokuujjkzkgpumiixhsastcdlwkndgvtzohekwveazjajqtqjleeqollatqoumbdttvuicyylyyqfnoaiacpklsquwabysdwhwwqnxgaahwbpgrbvflwforxzyvuqllljkyhedtvhghlbeypaxgjlwvqpacajrvizfubuclkukpcbanrblouacwxborioqlqwntwmvsbfuslolwzoevuknodjnipdnsfwchgqktfvsicrgkifpbfhzmmeidxmcslrrzbqfaumvofuxzrqoliuofxmiqbtdemjfdlyfuszpsjvzlrpijvbqrrzgtzsqdzwsjffxqgdkeztbckywkzvwchitzymhpdhxlcadisbsusjqasqhqczohqkgffnmczaxgqtaqldutoegevtfuoxwyshqrmpxumjegyubzjdjabjixebllhpeyhctkwuvbyvudnrmveqvjoildkwicmqbpmssrkexgtmbrnwvopmmpxtbsywhbdtpigmguayabybgrvngmlzdflomfaaffawfhtvngounhwoadbkgxyslmihsrfaanxlxrvjbuinmlhdauhmoeoddtyzrpyydcfwopzvxhjzxhjvwuqkyuartcimaaafwqtcfzqahplxgsnvttynalzfqoxtqaqvsacvwxpheuzuxscrlpglgqbtrhbetgdtnxsjenfnadoieihapyioodibgnveuqjldpddgrwuwnpbshioleeeiodiauvdaycvitarrfbcafzrhbbdmlxfcgieadnqewhidjmyederzdfmjvslrxaocadgcmqrxymmvjwmskhistfizfbkotblbhkrnrgqmihndtmdaaieymkfxijwavroisabxytrvaguhurmcileutcwccrupgcewguyodhhlmxokwwnwvifphhpxkevyjbwhoszwlanegqfzxatqspbchdvcilbjaelywwyvlkpndoysckpzanotjrubbdaliabdwzzphuyxovyyidizacmtcdgbawmavrstdsbtjvsgyngvglwpaoyokxvrzwfmyuuihisujwnplbfnywwkhdtnmevxbgunjijuqonvuziyerdmtabirbtyyitmnbnfxucbgjwngupkpfdawhumyxrdtbswkcbfdpmxnshtvrayurdczzxvxrhgixgydwldxdmhktrrkdcozypyudcslyfubwyzpjgwvjiosglwddaohzxmhoykcmuyvzcnluiiiligtmsvyuazmhqsppclfhtiufarswtsqnkiuveqbhpafwgjcqldimnwolrvvfcriermffsfxivupsdwlphxggfibevdfamdeixxqoewlfjnjofutpvvexsjtvcnpligtjkvupzouvzdldoaahwrsjcisvxbdoesbpxhggzzrsdpjsthlvuloqgqmeoqkkpitjlognozzevrchiwuyojxxmcbrjrmryhadgxnrtpoconfsrlnastddxfmelvlgletxeomqeytzrqovkfucnafpjrebsvlhxodktbjrevwfdvlcwvpirzojghfoajwidlsbsllemenoxxxsslpgqerkawbcghzbvhaifrefhcszxthlrzdnvtewqymhacootguinbnxahirwowovanuwakdhmnzomhiewbkrqdbngukthytlrpmmgkokjcbvpbejkqqzqrvuyjuoxsqmsfxrcplqptqvcvwttediluvpvcavvbkxuxystdiwhtahoruterwxlttyewqctfljvbmhuwptwvfdmbgaiizbzbjwgjsgbkbqzeijlpqqwjjazwkwravzoafcrqpvonvacxubxjgixohgwcgrdjckoyzhbysjhwcjiithcyingnovokvljmnayordejcqqzdyhygjbcgbiqgryqofykiquctrqfjyycvbaziusfpcgpcrheojxxdohuzjwkxhgervmmjbyqtvzwomomyysoajhlbvuddjbxddgnkewzhoxumyqhijyhwmhvsrwzifvsjjgznobhwydezgratiqsrefpyuxryzrqlfnugrysjyqlcdvxifpifjzdgovnplyhoupaemcveeiyxvralgxjgaruizcqtnxpyfgmrocyscuxpfufujzynuhvmkgltvwtqlmnsdozdbudrviwlbatlkexfzlffzgunfeowhesjznlzjxazvvluyxjtdrzwcvlrfbfkdfycssyfqvzufbyopwxmyiawjqzrwmeuygsfokbbuqqxzarrtqyafdpsdwiufdppgantwodywmthqnkkpxhkvvjmywxnnvgcbndevhbwpexlrmhovlhyhsdktyjkflgtpvhpljcrhesahnzumhmwwnsmluletbsaflzhmxxyovakxrjfossefwgoftlwxdjlnofxbnngdxggmuucwneirxpttchophkubrhkzlstgbyhnuesesckpwxebeljgdyuofyaumjukhezpwnnwlvdogwexnvzrnhxojyyqxfmtvaohsqeygeucwdqculpfvtvawqwqbhhgcjjakaglrfypypzcnjncdwxpesgtrdjrxihmaydmlckwajajgrzlfzyxcrduhdceouviceyilpreoykoznkpcpnefxoqtfrpryfzkcgjleekqzmvdtpkphizhzwkeoghnhntvzzddcktfarlndxtsfpvytxzputjtfaamaeadthlbbhzfkupcpbgmqwprtipvdtuyleqnfuddboknwonnnspdzsyzsxowdvdfylyssbaecdmfbelhnygnbjllamaffzamxdfypvccmarkjnwgqmxmiyzmtacjwumwopfhzztdcxagiylgytilwqqmqfuybspkeoqgbridomtbnsmgsuswjwawlfrscnoktchpjfhajwrvpdnlttirxuqpwhmnfxwwqxrbnnptjufedjffbjtwpfxmrttqluftzzethongmjyrijbdkvxofyxsdmkzposghnygogxlgbwhcbtrefngmiejqnecqjudkbdwtsegyskbwblypqfsclondxivoqpffbigoozsvanausclphvpelxfdndllhhpbojfrsyvzepyvwowgrdicuxfsvexwftbfwxllbnuedeopfuhlskmtrcrzhdtbynktdbtbqqmdlveoponhlzyjijhmjtddacunhsxrqojkhdubgxjxmfkhdqrbvqeqfouutupjdhvufvdacejlpjgijmpangrygqesmwbneiemqkbgetdyihedimbobgssaslsuiojgiwoabkelxxrdereurdfawgkimzsqcbjbtdhlugijrmkumjijkpunrhisasrcffqnrjxuupelacozsafrknwlkenwedaqgfdodaafnleaejqztyekzwyjmkgvdjxvtnyzbgvmtqlacpxhwnqslybbmulciemtxtlddrxgwcjrxluzyuybpzwnlrlgucogehkjuqmgtakgbzvgygyokjvovihonmwfihcegorqdntaszwppktjeyvdzcpldahooajunxfqcsvmdiylkbsjzlrdkudjhselfcgsslkaltzoprraqmrwcueeovewtvnjijwajxqkkvyihpnqdozzpwdowxmedhriupnkzjsxxcctahukarieqwouucruqjufakbcggbtkxlzpbqtidlyrucqpvfkooxcrvrsiylervdbrgeujxdkaqqlfsezposcutdceclqjrjifwqninyifhufhptweplfwrkgjfxomdebjlnhfenmbbhigjzqlzfidimgotorxwigihnsbhkiftdsfnbylhmeiitkfbpprfpfwhidlxxlvffkhpfyqhtwzuqvwnkbffdhncoezqkfqepdtesmzyuwoexuopqigzpkauutwjcoekxqbtywmfvrzmoehmebqhaskzozgosgusxcpfdliiitaelyorsttlkadedoeyggmkxnzieqswrbtnrmyrzbbapfbnkqjxiujhlbyvayubxmfsvczernyljhnzcvkqtnnkcflwnqeddtagwbhtigenmprkxozfsrfnokhohfluemsvaitszoumdtoaweeeuwbdzujpztwondmgehxtoybbyhokeqjygnywhswwtgrbqdlizrqzphqbgwqbfycbbdsbipxygkupuodqydxyozfuwedfnnxxfgutecxajoxfbqxxuyeqlxfcjzxkrnlsiyhwyjrficabmodjrhnoxlnvrtmbdetcmdqifxbwhrhezwvnuprmyvbglptzjdieyuiummydlyojzrximuuvkpbynvsbsjepxecuewnirzehanrolrxsluvfvsbkqmrfsxkcijpbxsgzqmomstxfixthioqbujeykshslgqmgmjfjtttvusymilqaihmhvgkbedmzkomfogukhibfsnuktvnrpouyouaqonvdiyqpvfcjdijmyxoopbqxzhndlrzavorwvpdcgxcgobqldjtncupsnyorscdxgpahwpkwyumduzttuoqmfqhhvcxbonlaendpfvpiwhhajmppnhvfrriucsgxrixlpuwppjvattugrjpuqtogxtdgjfzakpvwlbtrvyrzmmvcslyezgisjhtxnnnpkyxsnjvakmlidxejyhpwjggvyokfldereklkmnxlafjhpopvfrfjfnaokvcloyjfrguiyghiivjtqdtngrzkrjwwztanjznrxkxlkesryppqdxuknjizdoiwpcyyzdsnvocxqeodghvfzsieozzmcdhprltatsjjxmaipssdrmidfgoncxqwsmnfhtcnxexlocllejufgegvzdzawzeaoniuvsmbxyjahcbfzwxltktmzsagfojpvbhdbkzitcrqnnyrhiiwlqoxqxwfdojzxrtxgswexdldzdaevewzpjenslgozvyufmjkutxlpyvfcygvztxarvhkdgyenojregojwcjmfvmgbmuworqeqzyqvtwchojvwlyhqlqlttkyyygjhipcfhlotmratbdqvrpbnqpsudrvzszhbiqpaloxwaloaaokvsbzzexhkopgsbbvzzjbirypwutzkloudqfgfvtvkpnirwvtfvpcereuszwqolosdhjcdptazcskzawwhhjxzlettshxfbymihbnocdbjcxucgpuanwfrdhrulfjvykzxbdcayxixbmhpfrwebjwyatswoqkikfarrcfpnhtcpvcemghlvuftortehwhvbzlmzlnjpuxsyfrpmhrnpwybgojkcypyvcggordqkolgcbmabeknkpjyxkwonamlunxuvgfkzqhsoqephkpqddeyybawfnyvcnemdaxoktzkpfvdisbtsbiswgermlwggoawpwfxpnkcoyjxkpsszxydctivhfyenekxepjjmuzubycagyfxrucmwiavenwqwkinkyynxfpbzlajfcrawxnnqdvsgyvijgzqpfjixhdwgpfncgenrabomhxueoanwreurjokxbbdzfyvkqpsyvwiicqrxfjrhhfmvvbpcqilfzhwbbvufdcpqkmtgzfqwqyxhfimmftxxbhgihonnmxqbvlfukwtdduyiouvmuanizsskmyzlvuvidlzkzmmcpvaiictvkaiaetcnrfglmmrtxzaiulwxfkhunpkrsxwtayfetybnygfterqfrrdqdxqqppxrfupbwjewenuhzbuebzlaswtunfnrgtprdbgtktjljppbuyngzkoxnwegqpwvkihjkucohpyulupbsfmwpxljzwygzqnnsieyokobfqrdnrisasqfejxwkzzveqdcoxryunzgkprfnsfxetpmkitciqmnfzfnjjcbxbmjqfmzvmslavmgeyozhnroxpusvjxfyxehaybzcletchyxchbxocuewqudaegqfatcggvchebemdyevtkiimxkeveiaozpbssyycximzysfpdwxgvfhfackaccojltddzpfqdmelcavshyciroofqzamgjwbnpkpishenrrxjjagnumiupvdqwtwikylhfdudbdizlvainzmtfdubykxnvgrnrwtxsfoyklcaexolagvaqnfnqndrujnduvaptphmptlpivigqaigjkfnarugxoardyugyfreqrfiqcfzkvushdrygchlhockjxfmqimlbyeowyoghwmixzumnhbzufvvshkbpzeexoxaiugxtxgtloupjgpufdlqnuibnddnqlfauaehgvoikpwevurjducohjtouweklkynxexzmiqkpqhtmjfcpixwzjyxcxbvawjrzdbpltcasvlymvxosewajeuwfrsylbskfhwwlqtqwdcjujqxvtsgyocyygvfqxqoeajuglaofejgouyjgqrjksfenlvmxeqcbyxpkeodbflawnikiqmivgyfbolbnuottjkqfrltshxmhsqgdwjrjdltmfmawgrbeupqhhiokcascvdvoghvgvylabljnnkajbjldnyjnptydnbptegbnjykuntxhipfbrexkcvuzktvpwcaaoqnejwyficyutgponzzqbnhykffivnzargwvdgpvrjyqnkevtelkpjmkxxpaemuxyazsstqatljrjcokaoruoegemzceecptxuxdslyfmfbvpcncbjjualheyljrlmyaifxkiwevtrysavheqmlmsmpofkwvqlfrfueicaocnirbcvbovzuoxhfqhqwopeyyvjtimjmreqhiijiqpwnlakzbqdniriicmjgbhkdvbigbgkioovqbvoihjwwiblyrwafessikhnluojqtohxxzrragqxlvpeqhafbbvmwxciehqgnizjqgcyvcrwvsiwpxrskjguanaqmndduwirggibpfbrfumskknwwlardvystoguipjrllujzwatqhvhzhubtfxldqzvknepnspfvkdqbdqafuptiusbpruumirdxdjvazdglsryzhihexzyeuonebjatafufajxiobvthmrrvxbzzbrxpmsiemwofsktrugizlkcwijdfkruwaogezwoicrzwrwtgzeilgqbfspiaytclswnqjrobwowieqvzuogapjrjmzdzukufyabhonrhhgc";
        
        let index = str.index(str.startIndex , offsetBy: 7800)
        var substr=str.substring(from: index)

        var str_data = substr.data(using:.utf8)
        print("str count is \(str_data?.count) ")
        let packet = Packet(type: PacketType(rawValue: 100000),id:3, payload: str_data as! Data)
        socketManager.broadcastPacket(packet)
        }
}
