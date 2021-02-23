//
//  UIKitDurationTests.swift
//  RevealSpringAnimationTests
//
//  Created by Pan Yusheng on 2021/2/21.
//

import XCTest
@testable import RevealSpringAnimation

extension SpringCurve {
    // The time t such that |c2| * exp(a * t) = 0.001
    var estimatedDuration: Double {
        assert(0 < dampingRatio && dampingRatio < 1)

        let v0 = initialVelocity
        let zeta = dampingRatio

        let a = -omega * zeta
        let b = omega * sqrt(1 - zeta * zeta)
        let c2 = (v0 + a) / b

        // c2 should not equal to 0 if omega is found by OmegaSolver, since omega satisfies |c2| * exp(a * t) = 0.001
        return log(0.001 / abs(c2)) / a
    }
}

class UIKitDurationTests: XCTestCase {
    func testSolution(parameter: UIKitSpring, compareWithSystem: Bool = true) {
        let spring = SpringCurve(parameter)
        let systemSpring = SystemUIKitAnimationConverter.convert(uiValue: parameter)

        XCTAssertEqual(spring.estimatedDuration, parameter.duration, accuracy: 1e-8)

        if compareWithSystem {
            XCTAssertEqual(spring.omega, systemSpring.omega, accuracy: 1e-4)
        }
    }

    func testZeroVelocity() {
        testSolution(parameter: UIKitSpring(duration: 1, dampingRatio: 0.8, initialVelocity: 0))
    }

    func testNagativeVelocity() {
        let durations = [1.0, 3.0]
        let dampingRatios = stride(from: 0.1, to: 1.0, by: 0.1)
        let v0s = stride(from: -10.0, to: 0, by: 0.2)

        for d in durations {
            for zeta in dampingRatios {
                for v0 in v0s {
                    testSolution(parameter: UIKitSpring(duration: d, dampingRatio: zeta, initialVelocity: v0))
                }
            }
        }
    }

    // When the initial velocity is positive, system API has chaotic behavior, iOS 14.4
    func testChaos() {
        let data: [(zeta: Double, v0: Int, omega: Double)] = [
            (0.1, 210, 4.563081181386087),
            (0.1, 211, 4.562848965635916),
            (0.1, 212, 4.562616670674333),
            (0.1, 213, 4.562384288525174),
            (0.1, 214, 29.7174775875498),
            (0.1, 215, 0.21238673121318224),
            (0.1, 216, 0.03714229689742772),
            (0.1, 217, 4.5614538387698085),
            (0.1, 218, 4.561221235472331),
            (0.1, 219, 0.21632772288215876),
            (0.1, 220, 14.612212198062293),
            (0.1, 221, 0.056038597707982196),
            (0.1, 222, 0.21928154114275633),
            (0.1, 223, 0.22026821174440991),
            (0.1, 224, 0.22125317924244423),
            (0.1, 225, 0.2222380314940772),
            (0.1, 226, 0.22886274306886692),
            (0.1, 227, 0.22420723312191074),
            (0.1, 228, 0.22519344386142331),
            (0.1, 229, 0.22617838918213107),
            (0.1, 230, 0.22716328533973595),
            (0.1, 231, 4.558188096287089),
            (0.1, 232, 4.55795417620894),
            (0.1, 233, 1.3487210704577806),
            (0.1, 234, 78.16563507082961),
            (0.1, 235, 4.557252116619635),
            (0.1, 236, 4.557017911183073),
            (0.1, 237, 4.55678364809281),
            (0.1, 238, 4.556549293847785),
            (0.1, 239, 4.55631485952561),
            (0.1, 240, 4.556080345142903),
            (0.1, 241, 4.555845750711907),
            (0.1, 242, 4.55561107609808),
            (0.1, 243, 4.5553763212003435),
            (0.1, 244, 4.555141485944363),
            (0.1, 245, 4.5549065702922515),
            (0.1, 246, 4.554671493647424),
            (0.1, 247, 4.554436493396288),
            (0.1, 248, 4.554201340364016),
            (0.1, 249, 4.553965989201964),
            (0.1, 250, 4.553730784077176),
            (0.1, 251, 4.553495311646087),
            (0.1, 252, 4.553259904756891),
            (0.1, 253, 31.359200083698582),
            (0.1, 254, 0.25079307331164546),
            (0.1, 255, 0.2517772943916617),
            (0.1, 256, 6.972113790475847),
            (0.1, 257, 0.4299680051290053),
            (0.1, 258, 0.13398104574964204),
            (0.1, 259, 0.25571327074827294),
            (0.1, 260, 0.2566978588520846),
            (0.1, 261, 4.551136937345388),
            (0.1, 262, 0.2586665392763341),
            (0.1, 263, 20.81966718190041),
            (0.1, 264, 4.550427713635742),
            (0.1, 265, 0.26161852911692174),
            (0.1, 266, 4.048117816144064),
            (0.1, 267, 0.26358638286936564),
            (0.1, 268, 0.2645683013152148),
            (0.1, 269, 0.26555412624574115),
            (0.1, 270, 4.549007373764477),
            (0.1, 271, 4.5487702367533265),
            (0.1, 272, 4.548533237402283),
            (0.1, 273, 4.548296045931737),
            (0.1, 274, 4.5480587723296235),
            (0.1, 275, 4.547821415091565),
            (0.1, 276, 4.547583978249588),
            (0.1, 277, 12.059471247441625),
            (0.1, 278, 0.27440589375281726),
            (0.1, 279, 0.2753893530685444),
            (0.1, 280, 0.27637166641150285),
            (0.1, 281, 0.2773581593168305),
            (0.1, 282, 2.307634130788006),
            (0.1, 283, 0.2793248468786106),
            (0.1, 284, 0.2803085983878013),
            (0.1, 285, 4.545443143168735),
            (0.1, 286, 4.545205055725873),
            (0.1, 287, 4.5449667078160845),
            (0.1, 288, 5.215848307216217),
            (0.1, 289, 4.543650720554705),
            (0.1, 290, 2.5086144651337046),
            (0.1, 291, 4.54401246742506),
            (0.1, 292, 4.543773721692829),
            (0.1, 293, 0.2891564966574432),
            (0.1, 294, 4.543291281461728),
            (0.1, 295, 5.329992844952693),
            (0.1, 296, 0.2921075672406757),
            (0.1, 297, 0.29307395005651127),
            (0.1, 298, 0.2940693472210874),
            (0.1, 299, 0.29505665673534776),

            (0.5, 8300, 6.036899176854381),
            (0.5, 8310, 6.036411430813243),
            (0.5, 8320, 6.035923340175695),
            (0.5, 8330, 6.035434867407543),
            (0.5, 8340, 6.034945785098995),
            (0.5, 8350, 6.034457064239002),
            (0.5, 8360, 6.033967622798837),
            (0.5, 8370, 6.0334778391940755),
            (0.5, 8380, 6.032987690925929),
            (0.5, 8390, 6.032496897029083),
            (0.5, 8400, 6.032006443823415),
            (0.5, 8410, 6.031515292892914),
            (0.5, 8420, 6.031023798538413),
            (0.5, 8430, 6.030531960569156),
            (0.5, 8440, 1.6725711469554652),
            (0.5, 8450, 1.6745226211403375),
            (0.5, 8460, 1.6764746508860493),
            (0.5, 8470, 1.2161638627291715),
            (0.5, 8480, 1.6803776465385902),
            (0.5, 8490, 1.682328950356678),
            (0.5, 8500, 1.586902174547666),
            (0.5, 8510, 1.6854832911555062),
            (0.5, 8520, 1.4874387232971111),
            (0.5, 8530, 2.2659729571270892),
            (0.5, 8540, 3.0672925882127497),
            (0.5, 8550, 7.065866976384472),
            (0.5, 8560, 11.907937182447519),
            (0.5, 8570, 17.960913879069473),
            (0.5, 8580, 25.645587885141072),
            (0.5, 8590, 35.531163499252166),
            (0.5, 8600, 48.41871819674389),
            (0.5, 8610, 65.46059554987565),
            (0.5, 8620, 88.34987786318786),
            (0.5, 8630, 1.7096337858074047),
            (0.5, 8640, 1.7115831533412964),
            (0.5, 8650, 1.7135323890318703),
            (0.5, 8660, 1.715481492579348),
            (0.5, 8670, 1.7174304636832312),
            (0.5, 8680, 1.7193793020427646),
            (0.5, 8690, 1.7213280073563129),
            (0.5, 8700, 1.7232765793220035),
            (0.5, 8710, 1.725225017637426),
            (0.5, 8720, 1.7271733219992529),
            (0.5, 8730, 1.7291214921037603),
            (0.5, 8740, 1.7310695276466603),
            (0.5, 8750, 1.7330174283230952),
            (0.5, 8760, 1.7349651938276427),
            (0.5, 8770, 1.7369128238545304),
            (0.5, 8780, 1.7388603180972222),
            (0.5, 8790, 1.7408076762486078),
            (0.5, 8800, 1.7427548980007666),
            (0.5, 8810, 1.7447019830454238),
            (0.5, 8820, 1.7466489310742637),
            (0.5, 8830, 1.7485957417776496),
            (0.5, 8840, 1.7505424148450512),
            (0.5, 8850, 1.7524889499670462),
            (0.5, 8860, 1.754435346831977),
            (0.5, 8870, 1.756381605128161),
            (0.5, 8880, 1.7583277245433333),
            (0.5, 8890, 1.76027370476466),
            (0.5, 8900, 1.762219545478727),
            (0.5, 8910, 1.7641652463722555),
            (0.5, 8920, 1.7661108071296368),
            (0.5, 8930, 1.7680562274364509),
            (0.5, 8940, 203.51508302021844),
            (0.5, 8950, 107.0413776052242),
            (0.5, 8960, 60.955711391275386),
            (0.5, 8970, 42.806416990632705),
            (0.5, 8980, 31.712029613414174),
            (0.5, 8990, 24.22588500937873),
            (0.5, 9000, 18.830992984235376),
            (0.5, 9010, 14.755019824046247),
            (0.5, 9020, 11.562707327470852),
            (0.5, 9030, 8.989249288599845),
            (0.5, 9040, 6.862876509900243),
            (0.5, 9050, 5.064697234608043),
            (0.5, 9060, 3.5040031431029144),
            (0.5, 9070, 2.0934821057475768),
            (0.5, 9080, 0.665567109117879),
            (0.5, 9090, 37.648551096715046),
            (0.5, 9100, 1.5189238865595982),
            (0.5, 9110, 1.0864810879049218),
            (0.5, 9120, 4.947073597578973),
            (0.5, 9130, 1.8069346485571314),
            (0.5, 9140, 0.15021417699350384),
            (0.5, 9150, 5.9917706515280775),
            (0.5, 9160, 3.734107350635722),
            (0.5, 9170, 1.8147033500285341),
            (0.5, 9180, 1.8166424594758337),
            (0.5, 9190, 1.6987526619414803),
            (0.5, 9200, 1.8205283183147436),
            (0.5, 9210, 5.991062804938581),
            (0.5, 9220, 11.698345641466517),
            (0.5, 9230, 1.8263519324059805),
            (0.5, 9240, 5.989499195523138),
            (0.5, 9250, 1.8235772336314167),
            (0.5, 9260, 6.773709581802887),
            (0.5, 9270, 1.8339900718966882),
            (0.5, 9280, 1.836054686339025),
            (0.5, 9290, 8.796342610599178),
            (0.5, 9300, 18.468435217219305),
            (0.5, 9310, 5.985834954496713),
            (0.5, 9320, 5.908318048319084),
            (0.5, 9330, 1.8446538596308955),
            (0.5, 9340, 1.847693560517454),
            (0.5, 9350, 1.8496327040642826),
            (0.5, 9360, 1.8515718572598492),
            (0.5, 9370, 5.982682489979294),
            (0.5, 9380, 26.78137912269839),
            (0.5, 9390, Double.infinity),
            (0.5, 9400, 1.8593265716906617),
            (0.5, 9410, 3.731642276061635),
            (0.5, 9420, 1.8623210998282445),
            (0.5, 9430, 1.8651306168716624),
            (0.5, 9440, 1.8670788576884905),
            (0.5, 9450, 1.8690165277799018),
            (0.5, 9460, 1.8709540351624085),
            (0.5, 9470, 1.8728913832704635),
            (0.5, 9480, 1.8748285840393535),
            (0.5, 9490, 1.9207077814680942),
            (0.5, 9500, 5.975798068278093),
            (0.5, 9510, 5.975265643590921),
            (0.5, 9520, 37.00617051831046),
            (0.5, 9530, 43.98243678809593),
            (0.5, 9540, 24.38908749526827),
            (0.5, 9550, 1.8699144041897207),
            (0.5, 9560, 1.890311604459986),
            (0.5, 9570, 1.9372866717501662),
            (0.5, 9580, 1.894191681837885),
            (0.5, 9590, 1.8961270026571158),
            (0.5, 9600, 5.970455254309207),
            (0.5, 9610, 1.4714899874390408),
            (0.5, 9620, 5.969381708393846),
            (0.5, 9630, 1.9038672021539054),
            (0.5, 9640, 31.018597493642197),
            (0.5, 9650, 1.9077362492844776),
            (0.5, 9660, 5.96722858999799),
            (0.5, 9670, 1.9094640548622248),
            (0.5, 9680, 1.9135383773007346),
            (0.5, 9690, 1.9154723656032637),
            (0.5, 9700, 1.9174059557569085),
            (0.5, 9710, 1.9193394248929243),
            (0.5, 9720, 1.9212719905104905),
            (0.5, 9730, 1.9232057674297403),
            (0.5, 9740, 1.9251387562249802),
            (0.5, 9750, 1.9270715343639357),
            (0.5, 9760, 1.9290041411734944),
            (0.5, 9770, 1.930936023516525),
            (0.5, 9780, 1.9328687281842791),
            (0.5, 9790, 1.9348009210584936),
        ]

        for point in data {
            let zeta = point.zeta
            let v0 = Double(point.v0) / 10000.0
            let omega = point.omega

            let parameter = UIKitSpring(duration: 1 / zeta, dampingRatio: zeta, initialVelocity: v0)
            let systemSpring = SystemUIKitAnimationConverter.convert(uiValue: parameter)

            print("System omega \(systemSpring.omega), my omega \(SpringCurve(parameter).omega)")
            XCTAssertEqual(systemSpring.omega, omega, accuracy: 1e-8)
        }
    }

    // The solution omega is found at the minimum point
    func testMinimum() {
        let uiValue = UIKitSpring(duration: 2, dampingRatio: 0.5, initialVelocity: 1.9039496253244579)
        testSolution(parameter: uiValue, compareWithSystem: false)
    }

    func testPositiveVelocity() {
        let durations = [1.0, 3.0]
        let dampingRatios = stride(from: 0.1, to: 1.0, by: 0.1)
        let v0s = stride(from: 0.0, to: 100.0, by: 0.2)

        for d in durations {
            for zeta in dampingRatios {
                for v0 in v0s {
                    testSolution(parameter: UIKitSpring(duration: d, dampingRatio: zeta, initialVelocity: v0), compareWithSystem: false)
                }
            }
        }
    }
}
